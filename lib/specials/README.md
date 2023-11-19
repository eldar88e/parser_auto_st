
# Specials


## AWS S3 

If you want put a file to S3 bucket, so you have to add name of bucket in config file (config.yml)

    s3 = AwsS3.new(bucket_key = :us_court)

    # Put file in S3 bucket
    body = Dasher.new().get('http://file.pdf')
    key = 'filename.pdf'
    s3.put_file(body, key, metadata={})
    >>> "https://court-cases-activities.s3.amazonaws.com/test_4543643543"  #url to file

    # Get files in S3 bucket
    files = s3.find_files_in_s3(prefix: 'filename')
    >>> [{:key=>"test_4543643543", :etag=>"\"b3d444eab6de2dccde0fd17f9fc46137\"", :size=>105904, :last_modified=>2021-12-17 09:27:40 UTC}]

    # Delete files in S3 bucket with prefix
    s3.delete_files(prefix: 'filename')
    


#### Config

    AWS:
        buckets:
            bucket_key: BUCKETNAME (how it spells in S3)

You can add several buckets with different bucket keys. You can see all buckets by Storage: `Storage.new.buckets`
Class AwsS3 take BUCKETNAME in automatic by bucket_key. 


## Run id

Using Run_id table. You have to make ActiveRecord model of your __*\_runs__ table.
Firstly it tries to find existed run_id with status not finished, after that if it didn't find existed rows it will make a new one with new run_id

    # Start to work and get run_id.  
    run_id_class = RunId(active_record_model: CourtRuns)
    current_run_id = run_id_class.run_id

    ... Scraping ....

    # Change status on finish in the runs table 
    run_id_class.finish 



## MD5 Hash

A tool to create an md5_hash string from a hash.  
You can use existed tables with a permanent set of columns or add your own set of columns.

    # Make a class exemplar
    md5 = MD5Hash.new(:table=>:party)
    # or
    md5 = MD5Hash.new(:columns=>[:court_id, :case_id, :party_name, :party_type])
    # Generate md5_hash
    data = { court_id: 999, case_id: 12, party_name: 'Maxim', party_type: 'person' }
    md5.generate(data)
    >> "c6a76ebd863b2dd49ae2139479e9e8ab"
    # To get generated md5 
    md5_hash = md5.hash
    >> "c6a76ebd863b2dd49ae2139479e9e8ab"

For now the class has a set of tables with columns for court tables: **`:info, :party, :activities, :judgement, :complaint`**


_All questions to Maxim G_

_December 2021_
