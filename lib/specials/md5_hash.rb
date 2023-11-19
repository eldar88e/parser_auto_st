# frozen_string_literal: true

class MD5Hash
  attr_reader :hash, :columns

  def constant_columns
    {
      info:                   %i[court_id case_name case_id case_filed_date case_description case_type disposition_or_status status_as_of_date judge_name],
      info_root_us_courts:    %i[court_id case_name case_id case_filed_date case_description case_type disposition_or_status status_as_of_date judge_name],
      info_root:              %i[court_id case_name case_id case_filed_date case_description case_type disposition_or_status status_as_of_date judge_name],

      party:                     %i[court_id case_id party_name party_type],
      party_root_us_courts:      %i[court_id case_id party_name party_type],
      party_root:                %i[court_id case_number party_name party_type],

      activities:                   %i[court_id case_id activity_date activity_decs activity_pdf],
      activities_root_us_courts:    %i[court_id case_id activity_date activity_decs activity_pdf],
      activities_root:              %i[court_id case_id activity_date activity_decs activity_pdf],

      lawyer_root: %i[court_id case_number defendant_lawyer defendant_lawyer_firm plantiff_lawyer plantiff_lawyer_firm],

      judgment:    %i[court_id case_id party_name fee_amount judgment_amount judgment_date],
      complaint:    %i[court_id case_id party_name type filed_date requested_amount status description],

      pdfs_on_aws: %i[court_id case_id source_type aws_link source_link],
    }
  end

  # @param [Hash] args choose columns for existed table or give your array of columns, one of the two parameters needed
  # @option args [Symbol] :table Choose table from existed array :info, :party, :activities and etc to make md5_hash for that type
  # @option args [List] :column Array of columns for making md5_hash
  # @example
  #   md5 = PacerMD5.new(table: :party)
  #   data = { court_id: 5, case_id: 14, party_name: 'Maxim', party_type: 'person' }
  #   md5_hash = md5.generate(data)
  def initialize(**args)
    @columns =
      if !args[:table].nil?
        constant_columns[args[:table].to_sym]
      elsif !args[:columns].nil?
        args[:columns]
      end

    error_message = "You didn't use parameters `:table` or `:columns`. You should use the one from following tables: :#{constant_columns.keys.join(', :')} or give your array of columns (order is important)."
    raise error_message if @columns.nil?
  end

  # @param data [Hash] The hash with row data
  # @return md5_hash [String]
  def generate(data)
    data = Hashie::Mash.new(data)
    data = value_correction(data)

    all_values_str = ''
    @columns.each do |key|
      all_values_str = all_values_str + data[key].to_s
    end
    @hash = Digest::MD5.hexdigest all_values_str
  end


  private

  def value_correction(data)
    data[:activity_date]='0000-00-00' if data.include?(:activity_date) && (data[:activity_date]=='' || data[:activity_date]==nil) # default in db '0000-00-00' but in reading or writing data can be nill
    data
  end

end
