defmodule Kamansky.Services.Order do
  alias Kamansky.Sales.Orders
  alias Kamansky.Services.Ebay
  alias Kamansky.Services.Hipstamp

  @spec mark_order_shipped(Order.t) :: {:ok, Order.t}
  defp mark_order_shipped(%Order{ebay_id: ebay_id} = order) when not is_nil(ebay_id), do: Ebay.Order.mark_shipped(order)
  defp mark_order_shipped(%Order{hipstamp_id: hipstamp_id} = order) when not is_nil(hipstamp_id), do: Hipstamp.Order.mark_shipped(order)
  defp mark_order_shipped(%Order{} = order), do: Orders.mark_order_as_shipped(order)
end
