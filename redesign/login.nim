when defined(js):
  import sugar, httpcore, options, json
  import dom except Event

  include karax/prelude
  import karax / [kajax, kdom]

  import error
  import karaxutils

  type
    LoginModal* = ref object
      shown: bool
      onLogIn: proc ()
      onSignUp: proc ()
      error: Option[PostError]

  proc onLogInPost(httpStatus: int, response: kstring, state: LoginModal) =
    let status = httpStatus.HttpCode
    if status == Http200:
      state.shown = false
      state.onLogIn()
    else:
      # TODO: Karax should pass the content-type...
      try:
        let parsed = parseJson($response)
        let error = to(parsed, PostError)

        state.error = some(error)
      except:
        kout(getCurrentExceptionMsg().cstring)
        state.error = some(PostError(
          errorFields: @[],
          message: "Unknown error occurred."
        ))

  proc onLogInClick(ev: Event, n: VNode, state: LoginModal) =
    state.error = none[PostError]()

    let uri = makeUri("login")
    let form = dom.document.getElementById("login-form")
    # TODO: This is a hack, karax should support this.
    let formData = newFormData(form)
    ajaxPost(uri, @[], cast[cstring](formData),
             (s: int, r: kstring) => onLogInPost(s, r, state))

  proc onClose(ev: Event, n: VNode, state: LoginModal) =
    state.shown = false
    ev.preventDefault()

  proc newLoginModal*(onLogIn, onSignUp: proc ()): LoginModal =
    LoginModal(
      shown: false,
      onLogIn: onLogIn,
      onSignUp: onSignUp
    )

  proc show*(state: LoginModal) =
    state.shown = true

  proc render*(state: LoginModal): VNode =
    result = buildHtml():
      tdiv(class=class({"active": state.shown}, "modal modal-sm"),
           id="login-modal"):
        a(href="", class="modal-overlay", "aria-label"="close",
          onClick=(ev: Event, n: VNode) => onClose(ev, n, state))
        tdiv(class="modal-container"):
          tdiv(class="modal-header"):
            a(href="", class="btn btn-clear float-right",
              "aria-label"="close",
              onClick=(ev: Event, n: VNode) => onClose(ev, n, state))
            tdiv(class="modal-title h5"):
              text "Log in"
          tdiv(class="modal-body"):
            tdiv(class="content"):
              form(id="login-form"):
                genFormField(state.error, "username", "Username", "text", false)
                genFormField(
                  state.error,
                  "password",
                  "Password",
                  "password",
                  true
                )
              a(href="#reset-password-modal"):
                text "Reset your password"
          tdiv(class="modal-footer"):
            button(class="btn btn-primary",
                   onClick=(ev: Event, n: VNode) => onLogInClick(ev, n, state)):
              text "Log in"
            button(class="btn",
                   onClick=(ev: Event, n: VNode) =>
                    (state.onSignUp(); state.shown = false)):
              text "Create account"