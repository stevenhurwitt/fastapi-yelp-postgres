-- Macro to generate date spine for time series analysis
-- Useful for filling gaps in time series data

{% macro generate_date_spine(start_date, end_date, datepart='day') %}

    with date_spine as (
        select
            date::date as date_{{ datepart }}
        from generate_series(
            '{{ start_date }}'::timestamp,
            '{{ end_date }}'::timestamp,
            '1 {{ datepart }}'::interval
        ) as date
    )
    
    select * from date_spine

{% endmacro %}
