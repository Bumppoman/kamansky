defmodule Kamansky.Operations.Trends do
  import Ecto.Query, warn: false

  alias Kamansky.Repo
  alias Kamansky.Sales.Listings.Listing
  alias Kamansky.Stamps

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
        era_average_listing_time <-
          era_sold_listings_query
          |> join(:left, [l], o in assoc(l, :order))
          |> select([l, s, ..., o], avg(fragment("CASE WHEN ? IS NOT NULL THEN ? ELSE ? END", l.order_id, o.ordered_at - l.inserted_at, ^DateTime.utc_now() - l.inserted_at)))
          |> Repo.one()
      ) do
        {
          era.name,
          %{
            average_listing_time: average_listing_time(era_average_listing_time),
            conversion_percentage: conversion_percentage(era_total_listings, total_listings),
            percentage_of_total_listings: round((era_total_listings / total_listings) * 100),
            percentage_of_total_sales: round((era_total_sold / total_sold) * 100),
            total_cost:
              era_sold_listings_query
              |> select([l, s], sum(s.cost + s.purchase_fees))
              |> Repo.one(),
            total_sales_income: Repo.aggregate(era_sold_listings_query, :sum, :sale_price)
          }
        }
      end
    end
  end

  @spec average_listing_time(any) :: integer
  defp average_listing_time(%{seconds: seconds, days: days}), do: days + (if seconds > 43200, do: 1, else: 0)
  defp average_listing_time(_), do: 0

  @spec conversion_percentage(any, any) :: integer
  defp conversion_percentage(era_total_sold, total_listings) when is_integer(era_total_sold) and is_integer(total_listings) do
    round((era_total_sold / total_listings) * 100)
  end
  defp conversion_percentage(_, _), do: 0
end
