defmodule KamanskyWeb.CustomerLive.RawFormComponent do
  use Phoenix.Component

  import Kamansky.Helpers, only: [states: 0]
  import Phoenix.HTML
  import Phoenix.HTML.{Form, Link}

  @spec customer_form(map) :: Phoenix.LiveView.Rendered.t
  def customer_form(assigns) do
    ~H"""
    <div class="grid grid-cols-2">
      <div class="form-group required">
        <%= label @f, :name %>
        <div class="form-input">
          <%= text_input @f,
            :name,
            required: true,
            "phx-target": @target,
            "phx-keyup": (if @existing, do: "search_for_customers")
          %>
        </div>
        <%= if @existing and @searched do %>
          <div id="customers">
            <ul class="list-group">
              <%= if Enum.any?(@matching_customers) do %>
                <%= for customer <- @matching_customers do %>
                  <li class="list-group-item">
                    <%= link customer.name,
                      to: "#",
                      "phx-click": "select_customer",
                      "phx-target": @target,
                      "phx-value-customer_id": customer.id
                    %>
                  </li>
                <% end %>
              <% else %>
                <li class="list-group-item">No results</li>
              <% end %>
            </ul>
          </div>
        <% end %>
      </div>
      <div class="form-group">
        <%= label @f, :email %>
        <div class="form-input">
          <%= email_input @f, :email %>
        </div>
      </div>
    </div>
    <div class="form-group required">
      <%= label @f, :street_address, "Street Address" %>
      <div class="form-input">
        <%= text_input @f, :street_address, required: true %>
      </div>
    </div>
    <div class="grid grid-cols-6">
      <div class="col-span-3 form-group required">
        <%= label @f, :city %>
        <div class="form-input">
          <%= text_input @f, :city, required: true %>
        </div>
      </div>
      <div class="form-group required">
        <%= label @f, :state %>
        <div class="form-input">
          <%= select @f, :state, states() %>
        </div>
      </div>
      <div class="col-span-2 form-group required">
        <%= label @f, :zip, "ZIP Code" %>
        <div class="form-input">
          <%= text_input @f, :zip, required: true %>
        </div>
      </div>
    </div>
    """
  end

  @spec customer_info(map) :: Phoenix.LiveView.Rendered.t
  def customer_info(assigns) do
    ~H"""
    <div class="col form-group">
      <strong>Customer</strong><br />
      <%= @customer.name %><br />
      <%= @customer.street_address %><br />
      <%= @customer.city %>, <%= @customer.state %> <%= @customer.zip %><br />
      <%= if @customer.country, do: raw("#{@customer.country}<br />") %>
      <%= @customer.email %>
    </div>
    """
  end
end
