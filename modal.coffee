###
Modal

Display modal alerts or dialogs.

Modal has promise returning equivalents of the native browser:

- Alert
- Confirm
- Prompt

These accept the same arguments and return a promise fulfilled with
the same return value as the native methods.

You can display any element in the modal:

    modal.show myElement

###

Jadelet = require "./lib/jadelet"

{formDataToObject, handle, empty} = require "./util"

PromptTemplate = require "./templates/modal/prompt"
ModalTemplate = require "./templates/modal"
CancelButtonTemplate = require "./templates/cancel-button"
InputTemplate = require "./templates/input"

modal = ModalTemplate()

FocusTrap = Jadelet.exec """
  span(@focus tabindex=0)
"""

cancellable = true
modal.onclick = (e) ->
  if e.target is modal and cancellable
    Modal.hide()

document.addEventListener "keydown", (e) ->
  unless e.defaultPrevented
    if e.key is "Escape" and Modal.visible() and cancellable
      e.preventDefault()
      Modal.hide()

document.body.appendChild modal

closeHandler = null

prompt = (params) ->
  new Promise (resolve) ->
    element = PromptTemplate params

    Modal.show element,
      cancellable: false
      closeHandler: resolve
    element.querySelector(params.focus)?.focus()

module.exports = Modal =
  show: (element, options) ->
    # Close if open
    if modal.classList.contains "active"
      Modal.hide()

    if typeof options is "function"
      closeHandler = options
    else
      closeHandler = options?.closeHandler
      if options?.cancellable?
        cancellable = options.cancellable

    empty(modal).appendChild(element)
    modal.classList.add "active"

  hide: (dataForHandler) ->
    closeHandler?(dataForHandler)
    modal.classList.remove "active"
    cancellable = true
    empty(modal)

  visible: ->
    modal.classList.contains "active"

  alert: (message) ->
    prompt
      title: "Alert"
      message: message
      focus: "button"
      confirm: handle ->
        Modal.hide()

  prompt: (message, defaultValue="", title="Prompt") ->
    prompt
      title: title
      message: message
      focus: "input"
      inputElement: InputTemplate
        type: "text"
        value: defaultValue
      cancelButton: CancelButtonTemplate
        cancel: handle ->
          Modal.hide(null)
      confirm: handle ->
        Modal.hide modal.querySelector("input").value

  confirm: (message, title="Confirm") ->
    prompt
      title: title
      message: message
      focus: "button"
      cancelButton: CancelButtonTemplate
        cancel: handle ->
          Modal.hide(false)
      confirm: handle ->
        Modal.hide(true)

  form: (formElement, options={}) ->
    {
      cancellable
    } = options
    
    cancellable ?= false
    
    new Promise (resolve) ->
      submitHandler = handle (e) ->
        formData = new FormData(formElement)
        result = formDataToObject(formData)
        Modal.hide(result)

      formElement.addEventListener "submit", submitHandler

      focusFirstElement = (e) ->
        el = formElement.querySelector("""
          button,
          [href],
          input,
          select,
          textarea,
          [tabindex]:not([tabindex="-1"])
        """)

        if el
          e?.preventDefault()
          el.focus()

      Modal.show formElement,
        cancellable: cancellable
        closeHandler: (result) ->
          formElement.removeEventListener "submit", submitHandler
          focusTrap.remove()
          resolve(result)

      # Focus first focusable form element and trap focus in modal
      focusFirstElement()
      # tabindex focus trap
      focusTrap = FocusTrap
        focus: focusFirstElement
      formElement.appendChild focusTrap

      return
