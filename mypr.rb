#!/usr/bin/env ruby
require 'net/http'
require 'net/https'
require 'open-uri'
require 'openssl'

require 'rubygems'
require 'json'
require 'sinatra'
require 'haml'
require 'thin'

enable :sessions
set :session_secret, 'ylr#s2fU%puZ\,z/UFfZh:!?h\'Jxq}-Q0"NkV.wA,0-|X>=<N=Ao}NIl/!r^u^f'
set :public_folder, 'public'
set :environment, :production
set :server, 'thin'
set :bind, '0.0.0.0'
set :port, 3000

def access_token
    ARGV.first
end

def orgs
    github_api('/user/orgs').sort_by {|org| org['login'] }
end

def repos org
    github_api("/orgs/#{org}/repos", {'per_page' => '1000'}).sort_by {|repo| repo['full_name'] }
end

def pulls owner, repo
    github_api "/repos/#{owner}/#{repo}/pulls"
end

def github_api path, options = {}
    uri = URI("https://api.github.com#{path}?access_token=#{access_token}&#{options.map {|key, val| "#{key}=#{val}" }.join('&')}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    res = http.get(uri.request_uri, {"User-Agent" => "Ruby/#{RUBY_VERSION}"})
    JSON.parse res.body
end

def selected_repos
    repos_json = session[:repos]
    if repos_json.nil? || repos_json.empty?
        []
    else
        repos_json.map {|json| JSON.parse json }.sort_by {|repo| repo['full_name']}
    end
end

get '/' do
    @selected_repos = selected_repos
    if @selected_repos.empty?
        redirect to('/configure')
        return
    end

    @repos_with_pulls = @selected_repos.map do |repo|
        repo['pulls'] = pulls(*repo['full_name'].split('/'))
        repo
    end

    haml :index
end

get '/configure' do
    @orgs_with_repos = orgs.map do |org|
        org['repos'] = repos(org['login'])
        org
    end

    @selected_repos = selected_repos

    haml :configure
end

post '/configure' do
    session[:repos] = params.keys

    redirect to('/')
end

# get '/auth' do
#     # redirect to oauth endpoint here
# end

# post '/auth' do
#     # set auth cookie here
# end

# get '/:repo' do
    # proxy APIs?
# end
