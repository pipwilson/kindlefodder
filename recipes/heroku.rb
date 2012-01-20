#!/usr/bin/env ruby
require 'docs_on_kindle'

class Heroku < DocsOnKindle 

  def get_source_files

    # The start_url is any webpage that will contain the navigation structure
    # of the documentaion

    start_url = "http://devcenter.heroku.com/categories/add-on-documentation" 

    @start_doc = Nokogiri::HTML `curl -s #{start_url}`

    File.open("#{output_dir}/sections.yml", 'w') {|f|

      # extract_sections() is defined below.  It gets the sections of the ebook
      # out of the webpage docs navigation sidebar.

      f.puts extract_sections.to_yaml
    }
  end

  # This method is for the ebook metadata.

  def document 
    {
      # Fill these in with full paths if available
      # No sure yet what the proper dimensions are.

      'cover' => nil,
      'masthead' => nil,
    }
  end

  # This method extracts the sections from the html at the start_url

  # This method should return an Array of elements with the Hash structure you
  # see at the end.

  def extract_sections
    @start_doc.search('select[@id=quicknav] option').map {|o| 
      title = o.inner_text
      $stderr.puts "#{title}"
      { 
        title: title,
        articles: get_articles(`curl -s http://devcenter.heroku.com#{o[:value]}`) 
      }
    }
  end
  
  # This method extracts the articles from a page or HTML fragment representing 
  # a section and the articles it contains.

  # This method should return an Array containing elements with the Hash
  # structure you see near the end, AND it should save HTML fragments for the
  # articles. See the save_article() method.

  def get_articles html
    category_page = Nokogiri::HTML html 
    xs = category_page.search("ul.articles a").map {|x|
      title = x.inner_text.strip
      href = x[:href] =~ /^http/ ? x[:href] : "http://devcenter.heroku.com#{x[:href]}" 
      $stderr.puts "-  #{title}"
      save_article href
      { 
        title: title,
        url: href
      }
    }
  end

  # This method downloads the HTML for an article, extracts, the HTML fragment 
  # that contains content, and saves the fragment to a path.

  def save_article href
    /(?<filename>[\w-]+)$/ =~ href
    article_doc = Nokogiri::HTML `curl -s #{href}`    
    FileUtils::mkdir_p "#{output_dir}/articles"
    path = "#{output_dir}/articles/#{filename}"

    # Save just the HTML fragment that contains the article text. Throw out everything else.

    File.open(path, 'w') {|f| f.puts(article_doc.at('article').inner_html)}
  end
end

# RUN IT! This pulls down the documentation and turns it into the Kindle ebook.

Heroku.generate
