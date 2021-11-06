import { Hook } from "./hooks";

export const modalInit = {
  mounted() {
    const handleOpenCloseEvent = ((openCloseEvent: CustomEvent) => {
      if (openCloseEvent.detail.open === true) {
        document.body.classList.add('modal-open');
      } else {
        this.el.removeEventListener("kamansky:toggle-modal", handleOpenCloseEvent);
        document.body.classList.remove('modal-open');

        // This timeout gives time for the animation to complete
        setTimeout(() => this.pushEventTo(openCloseEvent.detail.id, "close", {}), 300);
      }
    }) as EventListener;

    // This listens to modal event from AlpineJS
    this.el.addEventListener("kamansky:toggle-modal", handleOpenCloseEvent);
  }
} as Hook;