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

options = ['y']
html    = html_for(options)
doc     = Nokogiri::HTML(html)
save_html(doc, options)

# Question 1
form = doc.search("form[action^='/#{SMART_ANSWER}']")
q1_values = form.search('input[type=radio]').map do |input|
  input['value']
end

q1_values.each do |q1_value|
  options = ['y', q1_value]

  html = html_for(options)
  doc = Nokogiri::HTML(html)
  save_html(doc, options)

  # Question 2
  form = doc.search("form[action^='/#{SMART_ANSWER}']")
  q2_values = form.search('input[type=radio]').map do |input|
    input['value']
  end

  q2_values.each do |q2_value|
    options = ['y', q1_value, q2_value]

    html = html_for(options)
    doc = Nokogiri::HTML(html)
    save_html(doc, options)

    # Question 3
    form = doc.search("form[action^='/#{SMART_ANSWER}']")
    q3_values = form.search('input[type=radio]').map do |input|
      input['value']
    end

    q3_values.each do |q3_value|
      options = ['y', q1_value, q2_value, q3_value]

      html = html_for(options)
      doc = Nokogiri::HTML(html)
      save_html(doc, options)

      # Question 4
      form = doc.search("form[action^='/#{SMART_ANSWER}']")
      q4_values = form.search('input[type=radio]').map do |input|
        input['value']
      end

      q4_values.each do |q4_value|
        options = ['y', q1_value, q2_value, q3_value, q4_value]

        html = html_for(options)
        doc = Nokogiri::HTML(html)
        save_html(doc, options)

        # Question 5
        form = doc.search("form[action^='/#{SMART_ANSWER}']")
        q5_values = form.search('input[type=radio]').map do |input|
          input['value']
        end

        p q5_values
      end
    end
  end
end
