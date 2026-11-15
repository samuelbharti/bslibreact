-- README.md is the home page, and its lifecycle badge sits alone in a
-- paragraph, which Quarto renders as a figure with the alt text as a
-- caption. Keep shields.io badges inline as plain linked images.
local function is_badge(block)
  local found = false
  block:walk({
    Image = function(img)
      if img.src:find("img.shields.io", 1, true) then
        found = true
      end
    end,
  })
  return found
end

function Figure(fig)
  if not is_badge(fig) then
    return nil
  end
  -- The figure took the alt text as its caption; give it back to the image.
  local alt = pandoc.utils.stringify(fig.caption.long)
  local inlines = pandoc.utils.blocks_to_inlines(fig.content):walk({
    Image = function(img)
      if #img.caption == 0 then
        img.caption = pandoc.Inlines(alt)
      end
      return img
    end,
  })
  return pandoc.Para(inlines)
end
