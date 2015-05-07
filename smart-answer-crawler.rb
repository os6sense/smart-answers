require 'bundler/setup'
require 'nokogiri'
require 'fileutils'
require 'yaml'

unless SMART_ANSWER = ARGV.shift
  puts "Usage: #{__FILE__} <name-of-smart-answer>"
  exit 1
end

responses_file = "#{SMART_ANSWER}-responses.yml"
RESPONSES = if File.exists?(responses_file)
  YAML.load(File.read(responses_file))
else
  {}
end

SMART_ANSWER_URL = "https://www.gov.uk/#{SMART_ANSWER}/"

def html_for(options)
  url = File.join(SMART_ANSWER_URL, options)
  `curl --silent #{url}`
end

def save_html(doc, options)
  directory = "#{SMART_ANSWER}-html"
  FileUtils.mkdir_p(directory)
  filename  = options.join('-') + '.html'
  path = File.join(directory, filename)
  File.open(path, 'w') { |f| f.puts(doc.to_html) }
end

def parse_question_page(options)
  html = html_for(options)
  doc  = Nokogiri::HTML(html)

  if doc.at('.outcome')
    save_html(doc, options + ['outcome'])
  elsif doc.at('.question .error-message')
    save_html(doc, options + ['error'])
  else
    save_html(doc, options)

    question_text = doc.at('.question h2').inner_text.strip

    form = doc.search("form[action^='/#{SMART_ANSWER}']")
    question_choices = form.search('input[type=radio]')
    if question_choices.any?
      question_choices.each do |input|
        parse_question_page options + [input['value']]
      end
    else
      responses = RESPONSES[question_text]
      unless responses.nil?
        responses.each do |response|
          parse_question_page options + [response.to_s]
        end
      else
        puts "Unknown question type: #{question_text}"
      end
    end
  end
end

parse_question_page(['y'])
