defmodule KamanskyWeb.ComponentLive.ConfirmationModalComponent do
  use KamanskyWeb, :live_component

  def render(assigns) do
    ~L"""
    <p><%= @message %></p>
    """
  end
end
