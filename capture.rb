require 'sinatra'
require 'byebug'
require 'redis'
require 'json'
require 'active_support/json'
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

    def received_at
      @json['received_at']
    end
  end

  class RequestSerializer
    include FastJsonapi::ObjectSerializer
    set_key_transform :dash

    attributes :headers, :body, :method, :path, :received_at
  end

  configure do
    set :redis, Redis.new
    set :public_folder, File.expand_path('dist')
    set :connections, []
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

    request_json = {
      id: SecureRandom.uuid,
      headers: headers,
      body: body,
      method: request.request_method,
      path: request.path_info,
      received_at: Time.now.utc,
    }.as_json

    redis.lpush REDIS_LIST, request_json.to_json
    redis.ltrim REDIS_LIST, 0, 19

    event_data = RequestSerializer.new(
      Request.new(request_json)
    ).serialized_json

    settings.connections.each { |out| out << "data: #{event_data}\n\n" }
    200
  end

  get '/api/requests', provides: 'text/event-stream' do
    stream :keep_open do |out|
      settings.connections << out
      out.callback { settings.connections.delete(out) }
    end
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
