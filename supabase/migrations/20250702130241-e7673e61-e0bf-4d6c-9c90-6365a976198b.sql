
-- Create the main fitness_submissions table to store all form data
CREATE TABLE public.fitness_submissions (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  age INTEGER NOT NULL,
  gender TEXT NOT NULL CHECK (gender IN ('male', 'female')),
  email TEXT NOT NULL,
  phone_number TEXT,
  height TEXT,
  weight TEXT,
  workout_choice TEXT NOT NULL CHECK (workout_choice IN ('bicepcurls', 'squats', 'pushups', 'plank')),
  experience TEXT NOT NULL CHECK (experience IN ('yes', 'no')),
  rep_count INTEGER DEFAULT 0,
  plank_duration DECIMAL DEFAULT 0,
  score DECIMAL DEFAULT 0,
  performance_rating TEXT,
  submission_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE public.fitness_submissions ENABLE ROW LEVEL SECURITY;

-- Create policy to allow anyone to insert data (since this is a public form)
CREATE POLICY "Anyone can submit fitness data" 
  ON public.fitness_submissions 
  FOR INSERT 
  WITH CHECK (true);

-- Create policy to allow reading data (for winner selection)
CREATE POLICY "Anyone can read fitness data" 
  ON public.fitness_submissions 
  FOR SELECT 
  USING (true);

-- Create function to automatically create daily tables and copy data
CREATE OR REPLACE FUNCTION public.create_daily_fitness_table()
RETURNS TRIGGER AS $$
DECLARE
  table_name TEXT;
  current_date_str TEXT;
BEGIN
  -- Generate table name based on current date
  current_date_str := TO_CHAR(CURRENT_DATE, 'YYYY_MM_DD');
  table_name := 'fitness_submissions_' || current_date_str;
  
  -- Create daily table if it doesn't exist
  EXECUTE format('
    CREATE TABLE IF NOT EXISTS public.%I (
      LIKE public.fitness_submissions INCLUDING ALL
    )', table_name);
  
  -- Insert the new record into the daily table
  EXECUTE format('
    INSERT INTO public.%I SELECT $1.*', table_name) 
  USING NEW;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically create daily tables and copy data
CREATE TRIGGER create_daily_fitness_table_trigger
  AFTER INSERT ON public.fitness_submissions
  FOR EACH ROW
  EXECUTE FUNCTION public.create_daily_fitness_table();

-- Create function to get random winner from today's submissions
CREATE OR REPLACE FUNCTION public.get_random_winner()
RETURNS TABLE (
  winner_name TEXT,
  winner_workout TEXT,
  winner_score DECIMAL,
  total_participants INTEGER
) AS $$
DECLARE
  table_name TEXT;
  current_date_str TEXT;
  rec RECORD;
BEGIN
  -- Generate today's table name
  current_date_str := TO_CHAR(CURRENT_DATE, 'YYYY_MM_DD');
  table_name := 'fitness_submissions_' || current_date_str;
  
  -- Check if today's table exists and has data
  IF EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'fitness_submissions_' || current_date_str
  ) THEN
    -- Get random winner from today's table
    EXECUTE format('
      SELECT name, workout_choice, score, 
             (SELECT COUNT(*) FROM public.%I) as total_count
      FROM public.%I 
      ORDER BY RANDOM() 
      LIMIT 1', table_name, table_name)
    INTO rec;
    
    IF rec IS NOT NULL THEN
      winner_name := rec.name;
      winner_workout := rec.workout_choice;
      winner_score := rec.score;
      total_participants := rec.total_count;
      RETURN NEXT;
    END IF;
  END IF;
  
  -- If no data in today's table, return from main table
  IF NOT FOUND THEN
    SELECT s.name, s.workout_choice, s.score,
           (SELECT COUNT(*) FROM public.fitness_submissions WHERE submission_date = CURRENT_DATE)
    INTO rec
    FROM public.fitness_submissions s
    WHERE s.submission_date = CURRENT_DATE
    ORDER BY RANDOM()
    LIMIT 1;
    
    IF rec IS NOT NULL THEN
      winner_name := rec.name;
      winner_workout := rec.workout_choice;
      winner_score := rec.score;
      total_participants := rec.total_count;
      RETURN NEXT;
    END IF;
  END IF;
END;
$$ LANGUAGE plpgsql;
