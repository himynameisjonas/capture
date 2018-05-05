require 'sinatra'
require 'byebug'
require 'redis'
require 'json'
require 'fast_jsonapi'

class Capture < Sinatra::Base
  REDIS_LIST = 'capture:requests'.freeze

  class Request
    def initialize(json)
      @json = json
    end

    def id
      @json['id'] || SecureRandom.uuid
    end

    def headers
      @json['headers']
    end

    def body
      @json['body']
    end

    def method
      @json['method']
    end

    def path
      @json['path']
    end
  end

  class RequestSerializer
    include FastJsonapi::ObjectSerializer
    attributes :headers, :body, :method, :path
  end

  configure do
    set :redis, Redis.new
    set :public_folder, File.expand_path('dist')
  end

  def redis
    settings.redis
  end

  def self.match_all(url, &block)
    get(url, &block)
    post(url, &block)
    put(url, &block)
    patch(url, &block)
    delete(url, &block)
  end


  match_all '/c/*' do
    body = request.env['rack.input'].read
    headers = Hash[
      *env.lazy
          .select { |k, _| k.start_with? 'HTTP_' }
          .map { |k, v| [k.sub(/^HTTP_/, ''), v] }
          .map { |k, v| [k.split('_').map(&:capitalize).join('-'), v] }
          .sort
          .flatten
    ]

    redis.lpush REDIS_LIST, {
      id: SecureRandom.uuid,
      headers: headers,
      body: body,
      method: request.request_method,
      path: request.path_info
    }.to_json
    redis.ltrim REDIS_LIST, 0, 19

    200
  end

  get '/api/requests' do
    requests = redis.lrange(REDIS_LIST, 0, 20).map do |json|
      Request.new(JSON.parse(json))
    end

    RequestSerializer.new(requests).serialized_json
  end

  get '*' do
    send_file 'dist/index.html'
  end
end
