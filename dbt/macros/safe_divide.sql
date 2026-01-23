-- Macro to safely divide two numbers, returning 0 if denominator is 0

{% macro safe_divide(numerator, denominator) %}
    case
        when {{ denominator }} = 0 then 0
        else {{ numerator }}::numeric / {{ denominator }}::numeric
    end
{% endmacro %}
