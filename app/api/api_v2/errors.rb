module APIv2

  class Error < Grape::Exceptions::Base
    attr :code, :text

    # code: api error code defined by Peatio
    # text: human readable error message
    # status: http status code
    def initialize(opts={})
      @code    = opts[:code]   || 1
      @text    = opts[:text]   || ''

      @status  = opts[:status] || 400
      @message = {error: {code: @code, message: @text}}
    end
  end

  class AuthorizationError < Error
    def initialize
      super code: 2, text: 'Authorization failed', status: 401
    end
  end

end
