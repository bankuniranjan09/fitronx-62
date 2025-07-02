
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
