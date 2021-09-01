defmodule KamanskyWeb.OrderLive.RawFormComponent do
  use Phoenix.Component

  import Phoenix.HTML.Form

  def order_form(assigns) do
    ~H"""
    <div class="row">
      <div class="col-md-6 form-group required">
        <%= label @f, :platform, class: "form-control-label" %>
        <div>
          <div class="form-check form-check-inline">
            <%= radio_button @f, :platform, :hipstamp, class: "form-check-input" %>
            <label class="form-check-label">Hipstamp</label>
          </div>
          <div class="form-check form-check-inline">
            <%= radio_button @f, :platform, :ebay, class: "form-check-input" %>
            <label class="form-check-label">eBay</label>
          </div>
        </div>
      </div>
      <div class="col-md-6 form-group required">
        <%= label @f,
          get_platform_id_field(@changeset),
          get_platform_id_field_label(@changeset),
          class: "form-control-label"
        %>
        <%= text_input @f, get_platform_id_field(@changeset), class: "form-control" %>
      </div>
    </div>
    <div class="row">
      <div class="col-md-6 form-group">
        <%= label @f, :item_price, "Subtotal", class: "form-control-label" %>
        <div class="input-group">
          <div class="input-group-prepend">
            <span class="input-group-text">
              <i class="material-icons">attach_money</i>
            </span>
          </div>
          <%= text_input @f, :item_price, class: "form-control" %>
        </div>
      </div>
      <div class="col-md-6 form-group">
        <%= label @f, :shipping_price, "Shipping", class: "form-control-label" %>
        <div class="input-group">
          <div class="input-group-prepend">
            <span class="input-group-text">
              <i class="material-icons">attach_money</i>
            </span>
          </div>
          <%= text_input @f, :shipping_price, class: "form-control" %>
        </div>
      </div>
    </div>
    <div class="row">
      <div class="col-md-6 form-group">
        <%= label @f, :selling_fees, class: "form-control-label" %>
        <div class="input-group">
          <div class="input-group-prepend">
            <span class="input-group-text">
              <i class="material-icons">attach_money</i>
            </span>
          </div>
          <%= text_input @f, :selling_fees, class: "form-control" %>
        </div>
      </div>
      <div class="col-md-6 form-group">
        <%= label @f, :shipping_cost, class: "form-control-label" %>
        <div class="input-group">
          <div class="input-group-prepend">
            <span class="input-group-text">
              <i class="material-icons">attach_money</i>
            </span>
          </div>
          <%= text_input @f, :shipping_cost, class: "form-control" %>
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
