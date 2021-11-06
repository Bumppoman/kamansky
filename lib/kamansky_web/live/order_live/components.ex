defmodule KamanskyWeb.OrderLive.Components do
  use Phoenix.Component

  import Phoenix.HTML.Form

  alias KamanskyWeb.Router.Helpers, as: Routes

  def bottom_tabs(assigns) do
    ~H"""
    <nav class="flex font-medium justify-center leading-6 mt-4">
      <%= for status <- [:pending, :processed, :shipped, :completed] do %>
        <%= live_redirect String.capitalize(Atom.to_string(status)),
          to: Routes.order_index_path(@socket, status),
          class: "block mr-3 px-4 py-2 text-gray-500" <> (if @live_action == status, do: " bg-blue-100 rounded-md text-blue-600", else: " text-opacity-70")
        %>
      <% end %>
    </nav>
    """
  end

  @spec order_form(map) :: Phoenix.LiveView.Rendered.t
  def order_form(assigns) do
    ~H"""
    <div class="grid grid-cols-2">
      <div class="form-group required">
        <div class="flex flex-col form-group required">
          <%= label @f, :platform, class: "w-full" %>
          <div class="align-middle flex-grow grid grid-cols-2 mt-2">
            <div class="flex items-center">
              <%= radio_button @f, :platform, :hipstamp, class: "align-top" %>
              <label for={input_id @f, :platform, :hipstamp}>Hipstamp</label>
            </div>
            <div class="flex items-center">
              <%= radio_button @f, :platform, :ebay, class: "align-top" %>
              <label for={input_id @f, :platform, :ebay}>eBay</label>
            </div>
          </div>
        </div>
      </div>
      <div class="form-group required">
        <%= label @f,
          get_platform_id_field(@changeset),
          get_platform_id_field_label(@changeset)
        %>
        <div class="form-input">
          <%= text_input @f, get_platform_id_field(@changeset) %>
        </div>
      </div>
    </div>
    <div class="grid grid-cols-2">
      <div class="form-group">
        <%= label @f, :item_price, "Subtotal" %>
        <div class="form-input">
          <div class="form-input-prepend">
            <span>$</span>
          </div>
          <%= text_input @f, :item_price %>
        </div>
      </div>
      <div class="form-group">
        <%= label @f, :shipping_price, "Shipping" %>
        <div class="form-input">
          <div class="form-input-prepend">
            <span>$</span>
          </div>
          <%= text_input @f, :shipping_price %>
        </div>
      </div>
    </div>
    <div class="grid grid-cols-2">
      <div class="form-group">
        <%= label @f, :selling_fees %>
        <div class="form-input">
          <div class="form-input-prepend">
            <span>$</span>
          </div>
          <%= text_input @f, :selling_fees %>
        </div>
      </div>
      <div class="form-group">
        <%= label @f, :shipping_cost %>
        <div class="form-input">
          <div class="form-input-prepend">
            <span>$</span>
          </div>
          <%= text_input @f, :shipping_cost %>
        </div>
      </div>
    </div>
    """
  end

  @spec get_platform_id_field(Ecto.Changeset.t) :: :ebay_id | :hipstamp_id
  defp get_platform_id_field(changeset) do
    changeset
    |> Ecto.Changeset.get_field(:platform)
    |> case do
      :ebay -> :ebay_id
      _ -> :hipstamp_id
    end
  end

  @spec get_platform_id_field_label(Ecto.Changeset.t) :: String.t
  defp get_platform_id_field_label(changeset) do
    changeset
    |> Ecto.Changeset.get_field(:platform)
    |> case do
      :ebay -> "eBay ID"
      _ -> "Hipstamp ID"
    end
  end
end
