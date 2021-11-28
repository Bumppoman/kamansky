defmodule KamanskyWeb.Helpers do
  @spec color_for_currency(Decimal.t) :: String.t
  def color_for_currency(amount) do
    cond do
      Decimal.lt?(amount, "0") -> "text-red-600"
      Decimal.gt?(amount, "0") -> "text-green-600"
      true -> ""
    end
  end
end
