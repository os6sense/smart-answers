require 'bundler/setup'
require 'nokogiri'
require 'fileutils'

SMART_ANSWER = 'additional-commodity-code'
BASE_URL     = "https://www.gov.uk/#{SMART_ANSWER}/"

def html_for(options)
  url = File.join(BASE_URL, options)
  `curl --silent #{url}`
end

def save_html(doc, options)
  directory = "#{SMART_ANSWER}-html"
  FileUtils.mkdir_p(directory)

  options.push('outcome') if doc.at('.outcome')
  filename  = options.join('-') + '.html'

  path = File.join(directory, filename)
  File.open(path, 'w') { |f| f.puts(doc.to_html) }
end

def crawl_multiple_choice_question(options)
  html    = html_for(options)
  doc     = Nokogiri::HTML(html)
  save_html(doc, options)

  form = doc.search("form[action^='/#{SMART_ANSWER}']")
  question_choices = form.search('input[type=radio]').map do |input|
    input['value']
  end

  question_choices.each do |choice|
    crawl_multiple_choice_question(options + [choice])
  end
end

crawl_multiple_choice_question(['y'])
