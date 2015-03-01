# word2vec Domains

## Generate Domain Name Ideas

This is a sample use of the [word2vec Mashape API](http://mashape.com/canadaduane/word2vec). Given the URL of an existing business, Domains will generate competitive alternative ideas for a business and domain name.

See http://domainthesaurus.witzy.org/ for a working example.

## word2vec

The algorithm at the heart of this example is called [GLoVe](http://nlp.stanford.edu/projects/glove/) and works similarly to Google's [word2vec](https://code.google.com/p/word2vec/).

A large corpus of text is analyzed for word co-occurrences and a high-dimensional space (e.g. 300 dimensions) is used to track the frequencies of co-occurrence. The resulting high-dimensional space can be used to find word similarities and interesting connections between brands, ideas, and language generally.

## Ruby Code

This example is built using Ruby and Sinatra (a micro-framework for web services). The main call to the Mashape word2vec API is in `domains.rb`:

```
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
```

This uses Mashape's [unirest](https://github.com/Mashape/unirest-ruby) ruby library to make a GET request to https://canadaduane-word2vec-v1.p.mashape.com. The `dictid` is a required parameter and can (at writing) be one of the following values: `common-300-100k`, `wiki-300`, `wiki-50`, or `gut19th-300-300k`.

| ID (dictid) | Dimensions | Vocabulary Size | Description |
| ----------- | ---------- | --------------- | ----------- |
| common-300-100k  | 300 | 100,000 | Common Crawl Data (the Internet) |
| wiki-300         | 300 | 300,000 | Wikipedia Data                   |
| wiki-50          | 50  | 300,000 | Wikipedia Data (50 dimensions)   |
| gut19th-300-300k | 300 | 300,000 | Gutenberg 19th Century Works     |

The `words` required parameter can be one or more words, separated by spaces, that will be combined into a single vector for lookup. When multiple words are combined, there are often some interesting "locations" to be found within the high-dimensional space that correspond to the additive vectors of each word's meaning. For instance "nails" can have multiple meanings--hand nails, or metal nails. Adding a second word will shift you closer to the meaning behind one or the other.

Pagination parameters are optional and should be passed after a `?`, e.g. `?page=1&per_page=10`.

We recommend putting the `MASHAPE_KEY` in a .rbenv-vars file in the same directory as this web micro-service after installing [rbenv-vars](https://github.com/sstephenson/rbenv-vars). Alternatively, start the app with `MASHAPE_KEY=[your api key] bundle exec ruby domains.rb`.

## Getting a Mashape Account

Visit http://mashape.com to sign up and get a mashape key. The API gives you several free calls per day, and there are monthly paid subscriptions for more frequent API usage.
