defmodule KamanskyWeb.LiveHelpers do
  import Phoenix.LiveView.Helpers

  @spec live_confirmation_modal(keyword) :: Phoenix.LiveView.Component.t
  def live_confirmation_modal(opts) do
    live_modal(
      KamanskyWeb.ComponentLive.ConfirmationModalComponent,
      Keyword.merge(
        opts,
        [
          button_action: Keyword.get(opts, :success),
          type: Keyword.get(opts, :type, :confirmation)
        ]
      )
    )
  end

  @doc """
  Renders a component inside the `KamanskyWeb.ModalComponent` component.

  The rendered modal receives a `:return_to` option to properly update
  the URL when the modal is closed.

  ## Examples

      <%= live_modal @socket, KamanskyWeb.StampLive.FormComponent,
        id: @stamp.id || :new,
        action: @live_action,
        stamp: @stamp,
        return_to: Routes.stamp_index_path(@socket, :index) %>
  """
  @spec live_modal(module, keyword) :: Phoenix.LiveView.Component.t
  def live_modal(component, opts \\ []) do
    with path <- Keyword.fetch!(opts, :return_to),
      button_text <- Keyword.get(opts, :button_text, opts[:title]),
      modal_opts <- [id: :modal, return_to: path, button_text: button_text, component: component, opts: opts]
    do
      live_component(KamanskyWeb.ComponentLive.ModalComponent, modal_opts)
    end
  end
end
