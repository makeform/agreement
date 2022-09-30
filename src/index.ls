module.exports =
  pkg:
    name: "@makeform/agreement", extend: name: '@makeform/common'
    i18n:
      "en": "未勾選": "not checked"
      "zh-TW": "未勾選": "未勾選"
  init: (opt) -> opt.pubsub.fire \subinit, mod: mod(opt)

mod = ({root, ctx, data, parent, t, i18n}) ->
  {ldview} = ctx
  lc = {value: null}
  id = "_#{Math.random!toString(36)substring(2)}"
  init: (base) ->
    @on \change, (v) ~>
      lc.value = !!v
      @mod.child.view.render <[input checkbox content]>
    _update = (v) ~> @value(lc.value = !!v)
    @mod.child.view = view = new ldview do
      root: root
      action: change:
        checkbox: ({node, ctx}) ~> _update if node.checked => true else false
      text:
        content: ({node}) ~>
          if @is-empty! => t("未勾選") else @mod.info.config.value or ""
        text: ({node}) ~> t(@mod.info.config.value or "")
      handler:
        input: ({node}) ~> node.classList.toggle \text-danger, @status! == 2
        checkbox: ({node}) ~>
          if !@mod.info.meta.readonly => node.removeAttribute \disabled
          else node.setAttribute \disabled, null
          node.checked = !!lc.value

  render: -> @mod.child.view.render!
  is-empty: (v) -> !v
  content: (v) -> !!v

