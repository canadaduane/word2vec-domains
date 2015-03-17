require "sinatra"
require "sinatra/json"
require "unirest"
require "dnsruby"
require "logger"
require "pp"

# Choose things from the beginning of the list more often than things
# from the end of the list.
def choose_leftishly(list)
  r1 = rand(list.size)
  r2 = rand(list.size)
  if r1 < r2
    list[r1]
  else
    list[r2]
  end
end

def domain_available?(domain)
  resolver = Dnsruby::Resolver.new(:nameserver => [
    "8.8.8.8",
    "8.8.4.4",
    "209.244.0.3",
    "209.244.0.4",
    "107.150.40.234",
    "50.116.23.211"
  ])
  attempts = 0
  begin
    resolver.query(domain)
  rescue Dnsruby::ResolvTimeout, Dnsruby::ServFail => e
    puts e
  end
  false
rescue Dnsruby::NXDomain
  true
end

class RelatedWords

  def initialize(dictid = "common")
    @dictid = dictid
  end

  def lookup(words, per_page = 10, page = 1)
    api_domain = "canadaduane-word2vec-v1.p.mashape.com"
    response = Unirest.get "https://#{api_domain}/lookup/#{@dictid}/#{words}",
      parameters: {
        :page => page,
        :per_page => per_page
      },
      headers:{
        "X-Mashape-Key" => ENV["MASHAPE_KEY"],
        "Accept" => "application/json"
      }
    if response.code == 200
      response.body.map{ |r| r["word"] }
    else
      raise "Error: #{response.code} #{response.raw_body}"
    end
  end

  def ordered_ideas(word)
    lookup(word, 25).
      sort_by{ |x| x.size }.
      reject{ |x| word.downcase.include?(x.downcase) }.
      select{ |x| x =~ /^[a-zA-Z]+$/ }
  end

  def gather_ideas(words, add_combined = false)
    related = {}
    words.each do |w|
      related[w] = ordered_ideas(w)
    end

    if add_combined
      # Add in a query for all words combined
      all_words = words.join(" ")
      related[all_words] = ordered_ideas(all_words)
    end

    return related.values.flatten(1).sort_by{ |x| x.size }
  end

  def generate_domain_ideas(words, n = 10, logger = Logger.new)
    ideas = gather_ideas(words)

    available = []
    unavailable = []

    found_available_count = 0

    # Limit our search since it's otherwise possible to loop forever
    # on domain name "ideas" and not find any available domains.
    (10 + n*3).times do
      w1 = choose_leftishly(ideas)
      w2 = choose_leftishly(ideas)
      domain_idea = "#{w1}#{w2}.com".downcase
      if domain_available?(domain_idea)
        available << domain_idea
        logger.info("generated domain idea: #{domain_idea}")
        found_available_count += 1
      else
        unavailable << domain_idea
        logger.info("generated domain idea: #{domain_idea} [NOT available]")
      end
      break if found_available_count >= n
      sleep 0.5 # give dns a break, we're not a DDoS
    end

    return {
      :available => available,
      :unavailable => unavailable
    }
  end
end

# rel = RelatedWords.new("wiki-300")
# rel = RelatedWords.new("gut19th-300-300k")
rel = RelatedWords.new("common")

# rel.generate_domain_ideas(ARGV)

set :public_folder, 'public'

get "/" do
  File.read(File.join('public', 'index.html'))
end

get "/ideas" do
  json(
    :description => "Domain Name Idea Generator using Mashape word2vec API",
    :api_url => "http://mashape.com/canadaduane/word2vec",
    :app_url => "http://github.com/canadaduane/word2vec-domains"
  )
end

get "/ideas/:input" do |input|
  logger.info("Searching for ideas related to '#{input}'")
  cleaned = input.gsub(/[^a-zA-Z, +]/, '')
  logger.info("Searching using cleaned input: '#{cleaned}'")
  words = cleaned.split(/, +/)

  begin
    number_of_ideas = Integer(params[:n] || 10)
    number_of_ideas = 20 if number_of_ideas > 20
  rescue ArgumentError => e
    number_of_ideas = 10
  end

  json rel.generate_domain_ideas(words, number_of_ideas, logger)
end
