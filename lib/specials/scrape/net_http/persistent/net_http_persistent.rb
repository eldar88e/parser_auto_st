class Net::HTTP::Persistent

  attr_accessor :socks_addr, :socks_port, :socks_user, :socks_passwd

  def initialize name: nil, proxy: nil, pool_size: DEFAULT_POOL_SIZE
    @name = name

    @debug_output = nil
    @proxy_uri = nil
    @no_proxy = []
    @headers = {}
    @override_headers = {}
    @http_versions = {}
    @keep_alive = 30
    @open_timeout = nil
    @read_timeout = nil
    @write_timeout = nil
    @idle_timeout = 5
    @max_requests = nil
    @max_retries = 1
    @socket_options = []
    @ssl_generation = 0 # incremented when SSL session variables change

    @socket_options << [Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1] if Socket.const_defined? :TCP_NODELAY

    @pool = Net::HTTP::Persistent::Pool.new size: pool_size do |http_args|
      if @proxy_uri.scheme == 'socks'
        socks_addr = @proxy_uri.host
        socks_port = @proxy_uri.port
        socks_user = @proxy_uri.user
        socks_passwd = @proxy_uri.password
        #proxy[:uri].host, proxy[:uri].port, proxy[:user], proxy[:password]
        TCPSocket.socks_username = socks_user
        TCPSocket.socks_password = socks_passwd
        Net::HTTP::Persistent::Connection.new Net::HTTP::SOCKSProxy(socks_addr, socks_port), http_args, @ssl_generation
      else
        Net::HTTP::Persistent::Connection.new Net::HTTP, http_args, @ssl_generation
      end
    end

    @certificate = nil
    @ca_file = nil
    @ca_path = nil
    @ciphers = nil
    @private_key = nil
    @ssl_timeout = nil
    @ssl_version = nil
    @min_version = nil
    @max_version = nil
    @verify_callback = nil
    @verify_depth = nil
    @verify_mode = nil
    @cert_store = nil

    @generation = 0 # incremented when proxy URI changes

    if HAVE_OPENSSL then
      @verify_mode = OpenSSL::SSL::VERIFY_PEER
      @reuse_ssl_sessions = OpenSSL::SSL.const_defined? :Session
    end

    self.proxy = proxy if proxy
  end

  def proxy= proxy
    @proxy_uri = case proxy
                 when :ENV then proxy_from_env
                 when URI::HTTP then proxy
                 when URI then proxy
                 when nil then # ignore
                 else raise ArgumentError, 'proxy must be :ENV or a URI::HTTP'
                 end

    @no_proxy.clear

    if @proxy_uri then
      @proxy_args = [
        @proxy_uri.hostname,
        @proxy_uri.port,
        unescape(@proxy_uri.user),
        unescape(@proxy_uri.password),
      ]

      @proxy_connection_id = [nil, *@proxy_args].join ':'

      if @proxy_uri.query then
        @no_proxy = CGI.parse(@proxy_uri.query)['no_proxy'].join(',').downcase.split(',').map { |x| x.strip }.reject { |x| x.empty? }
      end
    end

    reconnect
    reconnect_ssl
  end

  def connection_for uri
    use_ssl = uri.scheme.downcase == 'https'

    net_http_args = [uri.hostname, uri.port]

    # I'm unsure if uri.host or uri.hostname should be checked against
    # the proxy bypass list.
    if @proxy_uri.scheme != 'socks' and @proxy_uri and not proxy_bypass? uri.host, uri.port then
      net_http_args.concat @proxy_args
    else
      net_http_args.concat [nil, nil, nil, nil]
    end

    connection = @pool.checkout net_http_args

    http = connection.http

    connection.ressl @ssl_generation if connection.ssl_generation != @ssl_generation

    if not http.started? then
      ssl http if use_ssl
      start http
    elsif expired? connection then
      reset connection
    end

    http.keep_alive_timeout = @idle_timeout if @idle_timeout
    http.max_retries = @max_retries if http.respond_to?(:max_retries=)
    http.read_timeout = @read_timeout if @read_timeout
    http.write_timeout = @write_timeout if @write_timeout && http.respond_to?(:write_timeout=)

    return yield connection
  rescue Errno::ECONNREFUSED
    address = http.proxy_address || http.address
    port = http.proxy_port || http.port

    raise Error, "connection refused: #{address}:#{port}"
  rescue Errno::EHOSTDOWN
    address = http.proxy_address || http.address
    port = http.proxy_port || http.port

    raise Error, "host down: #{address}:#{port}"
  ensure
    @pool.checkin net_http_args
  end

end

