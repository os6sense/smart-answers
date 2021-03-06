# Ruby/YAML Smart Answers

README for Ruby and YAML-based smart answer flows

Smart answer flows are stored in `lib/smart_answer_flows/*.rb`. Corresponding text is in
`lib/smart_answer_flows/locales/*.yml`.
The code responsible for executing the flow of those questions is in the `lib` folder of this project.

## Smart answer syntax

### Storing data for later use

You can use the `precalculate`, `next_node_calculation` and `calculate` methods to store data for later use.

Use `precalculate` or `next_node_calculation` to store data for use within the same node.

Use `calculate` to store data for use with subsequent nodes.

The flow below illustrates the data available to the different Question node methods.

    multiple_choice :question_1 do
      option :q1_option

      next_node :question_2

      calculate :q1_calculated_answer do
        'q1-calculated-answer'
      end
    end

    multiple_choice :question_2 do
      option :q2_option

      save_input_as :q2_answer

      precalculate :q2_precalculated_answer do
        # responses            => ['q1_option']
        # q1_calculated_answer => 'q1-calculated-answer'
        # q2_answer            => nil

        'q2-precalculated-answer'
      end

      next_node_calculation :q2_next_node_calculated_answer do |response|
        # response                => 'q2_option'
        # responses               => ['q1_option']
        # q1_calculated_answer    => 'q1-calculated-answer'
        # q2_answer               => nil
        # q2_precalculated_answer => 'q2-precalculated-answer'

        'q2-next-node-calculated-answer'
      end

      validate do |response|
        # response                       => 'q2_option'
        # responses                      => ['q1_option']
        # q1_calculated_answer           => 'q1-calculated-answer'
        # q2_answer                      => nil
        # q2_precalculated_answer        => 'q2-precalculated-answer'
        # q2_next_node_calculated_answer => 'q2-next-node-calculated-answer'
      end

      define_predicate :q2_named_predicate do |response|
        # response                       => 'q2_option'
        # responses                      => ['q1_option']
        # q1_calculated_answer           => 'q1-calculated-answer'
        # q2_answer                      => nil
        # q2_precalculated_answer        => 'q2-precalculated-answer'
        # q2_next_node_calculated_answer => 'q2-next-node-calculated-answer'
      end

      next_node do |response|
        # response                       => 'q2_option'
        # responses                      => ['q1_option']
        # q1_calculated_answer           => 'q1-calculated-answer'
        # q2_answer                      => nil
        # q2_precalculated_answer        => 'q2-precalculated-answer'
        # q2_next_node_calculated_answer => 'q2-next-node-calculated-answer'
      end

      calculate :q2_calculated_answer do |response|
        # response                       => 'q2_option'
        # responses                      => ['q1_option', 'q2_option']
        # q1_calculated_answer           => 'q1-calculated-answer'
        # q2_answer                      => 'q2_option'
        # q2_precalculated_answer        => 'q2-precalculated-answer'
        # q2_next_node_calculated_answer => 'q2-next-node-calculated-answer'
      end
    end

### Question types

* `multiple_choice` - choose a single value from a list of values. Response is a string.
* `checkbox_question` - choose multiple values from a list of values. Response is a list.
* `country_select` - choose a single country.
* `date_question` - choose a single date
* `value_question` - enter a single string value (free text)
* `money_question` - enter a money amount. The response is converted to a `Money` object.
* `salary_question` - enter a salary as either a weekly or monthly money amount. Coverted to a `Salary` object.

### Defining next node rules

There are two syntaxes for defining next node rules. The older syntax uses a block which returns a symbol indicating the next node. This syntax is deprecated.

```ruby
next_node do |response|
  response == 'green' ? :green : :red
end
```

The disadvantage of this syntax is that it's not possible to analyze the flow to find out the possible paths through the flow. A newer syntax has been created which allows the flow to be analyzed and a [visualisation](http://www.gov.uk/check-uk-visa/visualise) to be produced.

Here is the same logic expressed using the new syntax:

```ruby
next_node_if(:green, responded_with('green')) )
next_node(:red)
```

The `responded_with` function actually returns a [predicate](http://en.wikipedia.org/wiki/Predicate_%28mathematical_logic%29) which will be invoked during processing. If the predicate returns `true` then the `:green` node will be next, otherwise the next rule will be evaluated. In this case the next rule says `:red` is the next node with no condition.

### Predicate helpers

* `responded_with(value)` - `value` can be either a string or an array of values
* `variable_matches(varname, value)` - `varname` is a symbol representing the name of the variable to test, `value` can be either a single value or an array
* `response_has_all_of(required_responses)` - only for checkbox questions, true if all of the required responses were checked. `required_responses` can be a single value or an array.
* `response_is_one_of(responses)` -  only for checkbox questions, true if ANY of the responses were checked. `responses` can be a single value or an array.

### Combining predicates

Predicates can be combined using logical conjunctions `|` or `&`:

```ruby
next_node_if(:orange, variable_matches(:first_colour, "red") & variable_matches(:second_colour, "yellow"))
next_node_if(:monochrome, variable_matches(:first_colour, "black") | variable_matches(:second_colour, "white"))
```

### Structuring rules by nesting

Predicates can also be organised by nesting using `on_condition`, e.g.

```ruby
on_condition(responded_with("red")) do
  next_node_if(:orange, variable_matches(:first_color, "yellow"))
  next_node(:red)
end
next_node(:blue)
```

Here's a truth table for the above scenario:

```
|       | Yellow | other
| Red   | orange | red
| other | blue   | blue
```

### Defining named predicates

Named predicates can also be defined using

```ruby
define_predicate(:can_has_cheesburger?) do |response|
  # logic here…
end

next_node_if(:something, can_has_cheesburger?)
```

## Testing Smart Answers

You need to use nested contexts/tests in order to test Ruby/YAML Smart Answers.

### Example Smart Answer Flow

    status :published

    multiple_choice :question_1 do
      option :A
      option :B

      next_node :question_2
    end

    multiple_choice :question_2 do
      option :C
      option :D

      next_node :question_3
    end

    multiple_choice :question_3 do
      option :E
      option :F

      next_node :outcome_1
    end

    outcome :outcome_1 do
    end

### Valid test using nested contexts

This test passes using the example flow above.

    setup do
      setup_for_testing_flow 'example-flow'
    end

    should "be on question 1" do
      assert_current_node :question_1
    end

    context "when answering question 1" do
      setup do
        add_response :A
      end

      should "be on question 2" do
        assert_current_node :question_2
      end

      context "when answering question 2" do
        setup do
          add_response :C
        end

        should "be on question 3" do
          assert_current_node :question_3
        end

        context "when answering question 3" do
          setup do
            add_response :E
          end

          should "be on outcome 1" do
            assert_current_node :outcome_1
          end
        end
      end
    end

### Invalid test - Not using nested contexts

This test will fail at `assert_current_node :question_2`.

    should "exercise the example flow" do
      setup_for_testing_flow 'example-flow'

      assert_current_node :question_1
      add_response :A
      assert_current_node :question_2
      add_response :C
      assert_current_node :question_3
      add_response :E
      assert_current_node :outcome_1
    end
