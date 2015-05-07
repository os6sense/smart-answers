require 'bundler/setup'
require 'nokogiri'
require 'fileutils'

SMART_ANSWER = 'am-i-getting-minimum-wage'
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

  unless doc.at('.outcome')
    question_text = doc.at('.question h2').inner_text.strip

    form = doc.search("form[action^='/#{SMART_ANSWER}']")
    question_choices = form.search('input[type=radio]')
    if question_choices.any?
      question_choices.each do |input|
        crawl_multiple_choice_question options + [input['value']]
      end
    else
      puts "Unknown question type: #{question_text}"
    end
  end
end

crawl_multiple_choice_question(['y'])
