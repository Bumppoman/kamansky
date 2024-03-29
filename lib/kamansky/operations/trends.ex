defmodule Kamansky.Operations.Trends do
  import Ecto.Query, warn: false

  alias Kamansky.Repo
  alias Kamansky.Sales.Listings.Listing
  alias Kamansky.Stamps

  @spec listing_data_by_grade :: [{String.t, map}]
  def listing_data_by_grade do
    for grade <- Stamps.Stamp.grade_classes() do
      with(
        grade_listings_query <-
          Listing
          |> join(:left, [l], s in assoc(l, :stamp))
          |> grade_filter(grade.start, grade.finish),
        grade_sold_listings_query <- where(grade_listings_query, status: :sold),
        grade_total_listings <- Repo.aggregate(grade_listings_query, :count),
        grade_total_sold_listings <- Repo.aggregate(grade_sold_listings_query, :count),
        grade_total_sold_cost <- total_cost(grade_sold_listings_query),
        grade_total_sales_income <- Repo.aggregate(grade_sold_listings_query, :sum, :sale_price)
      ) do
        {
          grade.name,
          %{
            average_listing_time: average_listing_time(grade_sold_listings_query),
            percent_sold: percent_sold(grade_total_sold_listings, grade_total_listings),
            profit_ratio: profit_ratio(grade_total_sales_income, grade_total_sold_cost),
            total_listings: grade_total_listings,
            total_sales_income: grade_total_sales_income,
            total_sold_cost: grade_total_sold_cost,
            total_sold_listings: grade_total_sold_listings
          }
        }
      end
    end
  end

  @spec sold_listing_data_by_era :: [{String.t, map}]
  def sold_listing_data_by_era do
    for era <- Stamps.StampReferences.StampReference.eras() do
      with(
        era_listings_query <-
          Listing
          |> join(:left, [l], s in assoc(l, :stamp))
          |> join(:left, [l, s], sr in assoc(s, :stamp_reference))
          |> where([l, s, sr], sr.year_of_issue >= ^era.start and sr.year_of_issue <= ^era.finish),
        era_sold_listings_query <- where(era_listings_query, status: :sold),
        era_total_listings <- Repo.aggregate(era_listings_query, :count),
        total_listings <- Repo.aggregate(Listing, :count),
        era_total_sold <- Repo.aggregate(era_sold_listings_query, :count),
        total_sold <-
          Listing
          |> where(status: :sold)
          |> Repo.aggregate(:count),
        era_average_listing_time <- average_listing_time(era_sold_listings_query),
        era_median_sale_price <-
          era_sold_listings_query
          |> select([l], fragment("PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY ?) AS median_sale_price", l.listing_price))
          |> Repo.one(),
        total_sold_cost <- total_cost(era_sold_listings_query),
        total_sales_income <- Repo.aggregate(era_sold_listings_query, :sum, :sale_price)
      ) do
        {
          era.name,
          %{
            average_listing_time: era_average_listing_time,
            conversion_percentage: conversion_percentage(era_total_sold, total_listings),
            median_sale_price: era_median_sale_price,
            percentage_of_total_listings: round((era_total_listings / total_listings) * 100),
            percentage_of_total_sales: round((era_total_sold / total_sold) * 100),
            profit_ratio: profit_ratio(total_sales_income, total_sold_cost),
            total_sold_cost: total_sold_cost,
            total_sales_income: total_sales_income
          }
        }
      end
    end
  end

  @spec average_listing_time(Ecto.Queryable.t) :: integer
  defp average_listing_time(query) do
    query
    |> join(:left, [l], o in assoc(l, :order))
    |> select(
      [l, s, ..., o],
      avg(
        fragment(
          "CASE WHEN ? IS NOT NULL THEN ? ELSE ? END",
          l.order_id,
          o.ordered_at - l.inserted_at,
          ^DateTime.utc_now() - l.inserted_at
        )
      )
    )
    |> Repo.one()
    |> case do
      %{secs: secs, days: days} when secs > 43200 -> days + 1
      %{days: days} -> days
      _ -> 0
    end
  end

  @spec conversion_percentage(any, any) :: integer
  defp conversion_percentage(era_total_sold, total_listings) when is_integer(era_total_sold) and is_integer(total_listings) do
    round((era_total_sold / total_listings) * 100)
  end
  defp conversion_percentage(_, _), do: 0

  @spec grade_filter(Ecto.Queryable.t, integer, integer) :: Ecto.Queryable.t
  defp grade_filter(query, 0, 39), do: where(query, [l, s], is_nil(s.grade) or (s.grade >= 0 and s.grade <= 39))
  defp grade_filter(query, start, finish), do: where(query, [l, s], s.grade >= ^start and s.grade <= ^finish)

  @spec percent_sold(integer, integer) :: float | integer
  defp percent_sold(sold, total) when sold == 0 or total == 0, do: 0
  defp percent_sold(sold, total), do: round((sold / total) * 100)

  @spec profit_ratio(any, any) :: Decimal.t
  defp profit_ratio(%Decimal{} = total_sales_income, %Decimal{} = total_cost) do
    total_sales_income
    |> Decimal.div(total_cost)
    |> Decimal.round(2)
  end
  defp profit_ratio(_, _), do: 0

  @spec total_cost(Ecto.Queryable.t) :: Decimal.t
  defp total_cost(query) do
    query
    |> select([l, s], sum(s.cost + s.purchase_fees))
    |> Repo.one()
  end
end
