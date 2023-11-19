module RetryBlock
  RETRY_MAX_DELAY = 256 # Max sleep before retry
  RETRY_TOT_DELAY = 3600 * 3 # 3 hours total, and raise

  def do_retry(has_conn)
    total_delay   = 0
    current_delay = 0

    begin
      connect if has_conn && @connection.nil?
      yield
    rescue Exception => e
      raise e if total_delay >= RETRY_TOT_DELAY

      cause_exc = e.cause.is_a?(Mysql2::Error) ? e.cause : e

      should_retry   = cause_exc.instance_of?(Mysql2::Error::ConnectionError)
      should_retry ||= cause_exc.instance_of?(Mysql2::Error::TimeoutError)
      if cause_exc.is_a?(Mysql2::Error)
        should_retry ||= cause_exc.error_number == 1028 # ER_FILSORT_ABORT
        should_retry ||= cause_exc.error_number == 1213 # ER_LOCK_DEADLOCK
        should_retry ||= cause_exc.error_number == 1317 # ER_QUERY_INTERRUPTED
        should_retry ||= cause_exc.error_number == 3024 # ER_QUERY_TIMEOUT
        should_retry ||= cause_exc.error_number == 1040 # ER_CON_COUNT_ERROR
        should_retry ||= cause_exc.error_number == 1053 # ER_SERVER_SHUTDOWN
      end

      raise e unless should_retry

      if has_conn && !@connection.nil?
        disconnect!
        @connection = nil
      end

      current_delay = current_delay.zero? ? 1 : 2 * current_delay
      current_delay = RETRY_MAX_DELAY if current_delay > RETRY_MAX_DELAY
      total_delay  += current_delay

      Hamster.logger.error "Connection error: #{e.class.name} -> sleeping: #{current_delay} seconds"
      Hamster.logger.error e.full_message

      sleep current_delay

      retry
    end
  end

  def retry_connection(&block)
    do_retry(false, &block)
  end

  def retry_query(&block)
    do_retry(true, &block)
  end
end

module Mysql2AdapterConnectionPatch
  include RetryBlock

  def new_client(config)
    project_part = "Project ##{Hamster.project_number}"
    stack_line   =
      caller
        .reject do |line|
          line.include?('/lib/ruby/gems/') || line.include?('/bundle/gems/')
        end
        .first

    stack_line ||= 'Unknown'
    work_dir     = "#{Dir.pwd}/"
    stack_line   = stack_line.sub(work_dir, '') if stack_line.start_with?(work_dir)

    conn_attrs = config[:connect_attrs] || {}
    conn_attrs[:origin] = "#{project_part}, #{stack_line}"

    retry_connection do
      Mysql2::Client.new(config.merge({ connect_attrs: conn_attrs }))
    end
  rescue Mysql2::Error => error
    if error.error_number == ActiveRecord::ConnectionAdapters::Mysql2Adapter::ER_BAD_DB_ERROR
      raise ActiveRecord::NoDatabaseError
    else
      raise ActiveRecord::ConnectionNotEstablished, error.message
    end
  end
end

module Mysql2AdapterQueryPatch
  include RetryBlock

  def execute(*args)
    retry_query { super(*args) }
  end

  def exec_stmt_and_free(*args, &block)
    retry_query { super(*args, &block) }
  end
end

require 'active_record/connection_adapters/mysql2_adapter'
ActiveRecord::ConnectionAdapters::Mysql2Adapter.singleton_class.prepend Mysql2AdapterConnectionPatch
ActiveRecord::ConnectionAdapters::Mysql2Adapter.prepend Mysql2AdapterQueryPatch
