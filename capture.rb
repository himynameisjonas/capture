require 'sinatra'
require 'byebug'
require 'redis'
require 'json'

class Capture < Sinatra::Base
  REDIS_LIST = 'capture:requests'.freeze

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
      headers: headers,
      body: body,
      method: request.request_method,
      path: request.path_info
    }.to_json
    redis.ltrim REDIS_LIST, 0, 19

    200
  end

  get '*' do
    send_file 'dist/index.html'
  end
end
