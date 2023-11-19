# frozen_string_literal: true

class AwsS3

  def initialize(bucket_key = :us_court, account=:us_court)
    @bucketname = Storage.new.buckets[bucket_key]
    s3 = get_aws_s3_client(account)
    @bucket = s3.bucket(@bucketname)
  end

  # Put file in bucket.
  # body - file
  # key - filename
  # metadata – hash with additional information about file
  def put_file(body, key, metadata={})
    # random_key = SecureRandom.uuid
    @bucket.put_object(
      acl: 'public-read',
      key: key,
      body: body,
      metadata: metadata
    )

    "https://#{@bucket.name}.s3.amazonaws.com/#{key}"
  end

  # Find all files in bucket with prefix
  def find_files_in_s3(prefix)
    files = []
    @bucket.objects({:prefix=>prefix}).each do |object|
      puts "#{object.key} => #{object.etag}"
      files.push({
                   key: object.key, etag: object.etag, size: object.size, last_modified: object.last_modified
                 })
    end
    p @bucket
    files
  end

  # Download file from bucket by key(filename)
  def download_file(key, filename=key)
    large_object = @bucket.object(key)
    large_object.download_file(filename)
  end

  # Delete all files with key(filename) started on key
  def delete_files(key)
    loop do
      keys_hash = @bucket.objects({:prefix=>key}).map { |obj| {key:obj.key} }
      break if keys_hash.empty?
      @bucket.delete_objects({delete:{objects:keys_hash[0..999]}})
    end
  end


  private

  # Get S3 client
  def get_aws_s3_client(account)
    aws_court_cases_activities =
      case account
      when :us_court
        Storage.new.aws_credentials
      when :loki
        Storage.new.aws_credentials_loki
      when :hamster
        Storage.new.aws_credentials_hamster_storage
      end
    Aws.config.update(
      access_key_id: (aws_court_cases_activities['access_key_id']).to_s,
      secret_access_key: (aws_court_cases_activities['secret_access_key']).to_s,
      region: 'us-east-1'
    )
    Aws::S3::Resource.new(region: 'us-east-1')
  end

end
