require 'bundler/setup'
require 'nokogiri'
require 'fileutils'
require 'yaml'

SMART_ANSWER = 'apply-tier-4-visa'
BASE_URL     = "https://www.gov.uk/#{SMART_ANSWER}/"

tier_4_visa_data = YAML.load(File.read('lib/data/apply_tier_4_visa_data.yml'))

RESPONSES = {
  "What is your Tier 4 sponsor number?" => tier_4_visa_data['post'].keys + tier_4_visa_data['online'].keys

  # "How old are you?" => [
  #   15, 17, 19, 23
  # ],
  # "How often do you get paid?" => [
  #   1, 31
  # ],
  # "How many hours do you work during the pay period?" => [
  #   10, 40
  # ],
  # "How much do you get paid before tax in the pay period?" => [
  #   0, 1000
  # ],
  # "How old were you at the time?" => [
  #   15, 17, 19, 23
  # ],
  # "How often did you get paid?" => [
  #   1, 31
  # ],
  # "How many hours of overtime do you work during the pay period?" => [
  #   0, 10
  # ],
  # "How many days per week do you live in the accommodation?" => [
  #   0, 3, 7
  # ],
  # "How much does your employer charge for accommodation per day?" => [
  #   10, 50
  # ],
  # "How much do you get paid for overtime per hour?" => [
  #   5, 20
  # ],
  # "How many hours did you work during the pay period?" => [
  #   10, 40
  # ]
}

def html_for(options)
  url = File.join(BASE_URL, options)
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
