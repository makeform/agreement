# sample code for rendering pdf into multiple canvas
pdfjsLib.getDocument(ctx).promise
  .then (pdf) ->
    lc = {}
    ps = [1 to pdf.num-pages].map (idx) ->
      pdf.getPage idx
        .then (page) ->
          vp = page.getViewport {scale: 1}
          box = node.getBoundingClientRect!
          vp = page.getViewport {scale: 2 * (box.width / vp.width)}
          canvas = document.createElement \canvas
          ctx = canvas.getContext \2d
          canvas.width = vp.width
          canvas.height = vp.height
          canvas.style <<<
            width: "#{box.width}px"
            height: "#{(box.width / vp.width) * vp.height}px"
          if !lc.height => lc.height = (box.width / vp.width) * vp.height
          node.appendChild canvas
          renderContext = canvasContext: ctx, viewport: vp
          page.render renderContext .promise
    Promise.all ps
      .then -> node.style.height = "#{pdf.num-pages * lc.height}px"
