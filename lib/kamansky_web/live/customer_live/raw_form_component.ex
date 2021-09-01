defmodule KamanskyWeb.CustomerLive.RawFormComponent do
  use Phoenix.Component

  import Kamansky.Helpers, only: [states: 0]
  import Phoenix.HTML
  import Phoenix.HTML.{Form, Link}

  @spec customer_form(map) :: Phoenix.LiveView.Rendered.t
  def customer_form(assigns) do
    ~H"""
    <div class="row">
      <div class="col-md-6 form-group required">
        <%= label @f,
          :name,
          class: "form-control-label"
        %>
        <%= text_input @f,
          :name,
          class: "form-control",
          required: true,
          "phx-target": @target,
          "phx-keyup": (if @existing, do: "search_for_customers")
        %>
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
      <div class="col-md-6 form-group">
        <%= label @f,
          :email,
          class: "form-control-label"
        %>
        <%= email_input @f,
          :email,
          class: "form-control"
        %>
      </div>
    </div>
    <div class="row">
      <div class="col form-group required">
        <%= label @f,
          :street_address,
          "Street Address",
          class: "form-control-label"
        %>
        <%= text_input @f,
          :street_address,
          class: "form-control",
          required: true
        %>
      </div>
    </div>
    <div class="row">
      <div class="col-md-6 form-group required">
        <%= label @f,
          :city,
          class: "form-control-label"
        %>
        <%= text_input @f,
          :city,
          class: "form-control",
          required: true
        %>
      </div>
      <div class="col-md-2 form-group required" id="customer-state-area" phx-update="ignore">
        <%= label @f,
          :state,
          class: "form-control-label"
        %>
        <%= select @f,
          :state,
          states(),
          class: "choices-select"
        %>
      </div>
      <div class="col-md-4 form-group required">
        <%= label @f,
          :zip,
          "ZIP Code",
          class: "form-control-label"
        %>
        <%= text_input @f,
          :zip,
          class: "form-control",
          required: true
        %>
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
