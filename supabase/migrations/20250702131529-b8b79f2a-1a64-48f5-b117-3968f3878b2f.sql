

-- Grant necessary permissions to the authenticator role
GRANT USAGE ON SCHEMA public TO authenticator;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticator;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticator;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticator;

-- Grant permissions to anon role for public access
GRANT USAGE ON SCHEMA public TO anon;
GRANT SELECT, INSERT ON public.fitness_submissions TO anon;
GRANT EXECUTE ON FUNCTION public.get_random_winner() TO anon;
GRANT EXECUTE ON FUNCTION public.create_daily_fitness_table() TO anon;

-- Ensure the policies are correct
DROP POLICY IF EXISTS "Anyone can submit fitness data" ON public.fitness_submissions;
DROP POLICY IF EXISTS "Anyone can read fitness data" ON public.fitness_submissions;

CREATE POLICY "Anyone can submit fitness data" 
  ON public.fitness_submissions 
  FOR INSERT 
  TO anon, authenticator
  WITH CHECK (true);

CREATE POLICY "Anyone can read fitness data" 
  ON public.fitness_submissions 
  FOR SELECT 
  TO anon, authenticator
  USING (true);

-- Fix the ambiguous column reference in get_random_winner function
DROP FUNCTION IF EXISTS public.get_random_winner();

CREATE OR REPLACE FUNCTION public.get_random_winner()
 RETURNS TABLE(winner_name text, winner_workout text, winner_score numeric, total_participants integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
  daily_table_name TEXT;
  current_date_str TEXT;
  rec RECORD;
BEGIN
  -- Generate today's table name
  current_date_str := TO_CHAR(CURRENT_DATE, 'YYYY_MM_DD');
  daily_table_name := 'fitness_submissions_' || current_date_str;
  
  -- Check if today's table exists and has data
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = daily_table_name
  ) THEN
    -- Get random winner from today's table
    EXECUTE format('
      SELECT name, workout_choice, score, 
             (SELECT COUNT(*) FROM public.%I) as total_count
      FROM public.%I 
      ORDER BY RANDOM() 
      LIMIT 1', daily_table_name, daily_table_name)
    INTO rec;
    
    IF rec IS NOT NULL THEN
      winner_name := rec.name;
      winner_workout := rec.workout_choice;
      winner_score := rec.score;
      total_participants := rec.total_count;
      RETURN NEXT;
      RETURN;
    END IF;
  END IF;
  
  -- If no data in today's table, return from main table
  SELECT s.name, s.workout_choice, s.score,
         (SELECT COUNT(*) FROM public.fitness_submissions WHERE submission_date = CURRENT_DATE) as total_count
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
END;
$function$;

-- Grant execute permission on the updated function
GRANT EXECUTE ON FUNCTION public.get_random_winner() TO anon;
GRANT EXECUTE ON FUNCTION public.get_random_winner() TO authenticator;

