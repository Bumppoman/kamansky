defmodule KamanskyWeb.ComponentLive.ConfirmationModalComponent do
  use KamanskyWeb, :live_component

  @spec render(map) :: Phoenix.LiveView.Rendered.t
  def render(assigns) do
    ~L"""
    <p><%= @message %></p>
    """
  end
end
