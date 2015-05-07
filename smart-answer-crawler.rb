require 'bundler/setup'
require 'nokogiri'
require 'fileutils'

SMART_ANSWER = 'am-i-getting-minimum-wage'
BASE_URL     = "https://www.gov.uk/#{SMART_ANSWER}/"

RESPONSES = {
  "How old are you?" => [
    15, 17, 19, 23
  ],
  "How often do you get paid?" => [
    1, 31
  ],
  "How many hours do you work during the pay period?" => [
    10, 40
  ],
  "How much do you get paid before tax in the pay period?" => [
    0, 1000
  ],
  "How old were you at the time?" => [
    15, 17, 19, 23
  ],
  "How often did you get paid?" => [
    1, 31
  ],
  "How many hours of overtime do you work during the pay period?" => [
    0, 10
  ],
  "How many days per week do you live in the accommodation?" => [
    0, 3, 7
  ],
  "How much does your employer charge for accommodation per day?" => [
    10, 50
  ],
  "How much do you get paid for overtime per hour?" => [
    5, 20
  ]
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

def crawl_multiple_choice_question(options)
  html = html_for(options)
  doc  = Nokogiri::HTML(html)

  if doc.at('.outcome')
    save_html(doc, options + ['outcome'])
  else
    question_text = doc.at('.question h2').inner_text.strip
    error_message = doc.at('.question .error-message')

    if error_message
      save_html(doc, options + ['error'])
    else
      save_html(doc, options)

      form = doc.search("form[action^='/#{SMART_ANSWER}']")
      question_choices = form.search('input[type=radio]')
      if question_choices.any?
        question_choices.each do |input|
          crawl_multiple_choice_question options + [input['value']]
        end
      else
        responses = RESPONSES[question_text]
        unless responses.nil?
          responses.each do |response|
            crawl_multiple_choice_question options + [response.to_s]
          end
        else
          puts "Unknown question type: #{question_text}"
        end
      end
    end
  end
end

crawl_multiple_choice_question(['y'])
