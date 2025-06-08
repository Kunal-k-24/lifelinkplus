-- Enable RLS
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Policy for SELECT (download) operations
CREATE POLICY "Allow public read access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'medical-files' );

-- Policy for INSERT (upload) operations
CREATE POLICY "Allow public insert access"
ON storage.objects FOR INSERT
WITH CHECK ( bucket_id = 'medical-files' );

-- Policy for DELETE operations
CREATE POLICY "Allow public delete access"
ON storage.objects FOR DELETE
USING ( bucket_id = 'medical-files' );

-- Policy for UPDATE operations
CREATE POLICY "Allow public update access"
ON storage.objects FOR UPDATE
USING ( bucket_id = 'medical-files' )
WITH CHECK ( bucket_id = 'medical-files' ); 