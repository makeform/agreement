module.exports =
  pkg:
    name: "@makeform/agreement", extend: name: '@makeform/common'
    dependencies: []
    i18n:
      "en":
        "未勾選": "not checked"
        "open": "Open this document in new window"
      "zh-TW":
        "未勾選": "未勾選"
        "open": "在新視窗開啟此文件"
  init: (opt) -> opt.pubsub.fire \subinit, mod: mod(opt)

mod = ({root, manager, ctx, data, parent, t, i18n}) ->
  {ldview} = ctx
  lc = {value: null}
  id = "_#{Math.random!toString(36)substring(2)}"
  pdfjsLib = null
  get-pdfjs = ->
    url =
      lib: \https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.9.179/pdf.min.js
      worker: \https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.9.179/pdf.worker.min.js
    (ctx) <- manager.rescope.load([{url: url.lib}]).then _
    pdfjsLib := ctx.pdfjsLib
    pdfjsLib.GlobalWorkerOptions.workerSrc = url.worker
    pdfjsLib
  init: (base) ->
    @on \change, (v) ~>
      lc.value = !!v
      @mod.child.view.render <[input checkbox content]>
    _update = (v) ~> @value(lc.value = !!v)
    @on \meta, (v) ~>
    @mod.child.view = view = new ldview do
      root: root
      action: change:
        checkbox: ({node, ctx}) ~> _update if node.checked => true else false
      text:
        content: ({node}) ~>
          if @is-empty! => t("未勾選") else @mod.info.config.value or ""
        text: ({node}) ~> t(@mod.info.config.value or "")
      handler:
        document:
          list: ~> @mod.info.config.documents or []
          key: -> it
          view:
            init:
              link: ({node, ctx}) ~>
                link = ctx
                is-html = /\.html/.exec(link)
                is-pdf = /\.pdf/.exec(link)
                <- node.addEventListener \load, _
                if is-pdf and node.nodeName.toLowerCase! == \object =>
                  get-pdfjs!
                    .then -> pdfjsLib.getDocument(ctx).promise
                    .then (pdf) ->
                      (page) <- pdf.getPage 1 .then _
                      vp = page.getViewport {scale: 1}
                      box = node.getBoundingClientRect!
                      vp = page.getViewport {scale: 1 * (box.width / vp.width)}
                      # 56: estimated viewer header height
                      # for long document, we provide a small viewport only for better scrolling experience.
                      # otherwise we extend the viewport to fix the whole document in.
                      return if pdf.num-pages > 3 => window.innerHeight * 0.66
                      else pdf.num-pages * (box.width / vp.width) * vp.height + 56
                    .then (h) -> node.style.minHeight = "#{h}px"
                else if is-html =>
                  <- debounce 1000 .then _
                  node.setAttribute \scrolling, \no
                  height = node.contentDocument.body.parentNode.scrollHeight
                  node.style.height = "#{height}px"
            handler:
              "for-html": ({node, ctx}) ~>
                link = ctx
                node.classList.toggle \d-none, !/\.html/.exec(link)
              open: ({node, ctx}) ~> node.textContent = t("open")
              link: ({node, ctx}) ~>
                link = ctx
                n = node.nodeName.toLowerCase!
                if link == node.dataset.link => return
                node.dataset.link = link
                is-html = /\.html/.exec(link)
                if n in <[object embed]> => node.classList.toggle \d-none, is-html
                if n in <[iframe]> => node.classList.toggle \d-none, !is-html
                if n == "a" => node.setAttribute \href, link
                else if n == "object" => node.setAttribute \data, link
                else node.setAttribute \src, link
        input: ({node}) ~> node.classList.toggle \text-danger, @status! == 2
        checkbox: ({node}) ~>
          if !@mod.info.meta.readonly => node.removeAttribute \disabled
          else node.setAttribute \disabled, null
          node.checked = !!lc.value
        "checkbox-for-view": ({node}) ~>
          node.checked = !!lc.value

  render: -> @mod.child.view.render!
  is-empty: (v) -> !v
  content: (v) -> !!v

