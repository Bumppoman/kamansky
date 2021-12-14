defmodule KamanskyWeb.Helpers do
  import Decimal, only: [is_decimal: 1]

  @spec color_for_currency(Decimal.t) :: String.t
  def color_for_currency(amount) do
    cond do
      is_decimal(amount) and Decimal.lt?(amount, "0") -> "text-red-600"
      is_decimal(amount) and Decimal.gt?(amount, "0") -> "text-green-600"
      true -> ""
    end
  end
end
