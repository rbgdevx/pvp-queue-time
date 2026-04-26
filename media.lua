local _, NS = ...

local LibStub = LibStub

-- Fix LSM30_Font widget: when SetFont fails for a font file, the FontString becomes
-- invisible, causing blank entries in the dropdown. This hooks AceGUI:Create to patch
-- each LSM30_Font widget's ToggleDrop so that failed SetFont calls fall back to the
-- default game font, ensuring every entry is always visible.
do
  local AceGUI = LibStub("AceGUI-3.0")
  local Media = LibStub("LibSharedMedia-3.0")
  local origCreate = AceGUI.Create

  AceGUI.Create = function(self, widgetType, ...)
    local widget = origCreate(self, widgetType, ...)
    if widgetType == "LSM30_Font" then
      local dropButton = widget.frame.dropButton
      local origOnClick = dropButton:GetScript("OnClick")

      dropButton:SetScript("OnClick", function(btn, mouseButton)
        -- If the dropdown is about to open (not already open), we need to
        -- handle it ourselves to add SetFont fallback protection.
        if not widget.dropdown then
          widget.list = widget.list or Media:HashTable("font")
          origOnClick(btn, mouseButton)

          -- After the dropdown opens, walk all content frames and fix any
          -- that have invisible text due to SetFont failure.
          -- GetFont() can return non-nil even when SetFont failed (inherited
          -- from GameFontWhite), so we must re-try SetFont and check its
          -- return value to detect actual failures.
          if widget.dropdown and widget.dropdown.contentRepo then
            for _, f in ipairs(widget.dropdown.contentRepo) do
              local name = f.text:GetText()
              if name then
                local fontPath = Media:Fetch("font", name)
                local _, size, outline = f.text:GetFont()
                size = size or 10
                outline = outline or ""
                if not fontPath or not f.text:SetFont(fontPath, size, outline) then
                  f.text:SetFont(STANDARD_TEXT_FONT, size, outline)
                  f.text:SetText(name)
                end
              end
            end
          end
        else
          origOnClick(btn, mouseButton)
        end
      end)
    end
    return widget
  end
end
