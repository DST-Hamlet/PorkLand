local function filter(t, callback)
    local result = {}
    for i, v in ipairs(t) do
        if callback(v) then
            table.insert(result, v)
        end
    end
    return result
end

local function NextMultipleOf(n, target)
    local remainder = n % target
    if remainder == 0 then
        return n
    end
    return n + (target - remainder)
end

local function BboxIntersects(bbox1, bbox2)
    return not (
        bbox2.x >= bbox1.x + bbox1.width or
        bbox2.x + bbox2.width <= bbox1.x or
        bbox2.y + bbox2.height <= bbox1.y or
        bbox2.y >= bbox1.y + bbox1.height
    )
end

local function TryInsert(block, width, height, fit_blocks)
    local align = 4
    local x = 0
    local y = 0

    local bboxH = block.height
    local bboxW = block.width
    while (y + bboxH < height) do
        local minY = nil
        local yTestBBox = { x = 0, y = y, width = width, height = bboxH }
        local tempBBoxs = filter(fit_blocks, function(fittedBlock)
            return BboxIntersects(fittedBlock, yTestBBox)
        end)

        while (x + bboxW <= width) do
            local testBBox = { x = x, y = y, width = bboxW, height = bboxH }
            local intersects = false
            for _, bbox in ipairs(tempBBoxs) do
                if BboxIntersects(bbox, testBBox) then
                    x = NextMultipleOf(bbox.x + bbox.width, align)
                    if minY == nil then
                        minY = bbox.height + bbox.y
                    else
                        minY = math.min(minY, bbox.height + bbox.y)
                    end

                    intersects = true
                    break
                end
            end
            if not intersects then
                return { x = x, y = y, width = bboxW, height = bboxH }
            end
        end
        if minY then
            y = math.max(NextMultipleOf(minY, align), y + align)
        else
            y = y + align
        end
        x = 0
    end
end

local function Pack(width, height, blocks)
    local sorted_blocks = shallowcopy(blocks)

    table.sort(sorted_blocks, function(a,b)
        return b.width * b.height > a.width * a.height
    end)

    local fit_blocks = {}
    for _, block in ipairs(sorted_blocks) do
        block.insert_bbox = TryInsert(block, width, height, fit_blocks)
        if not block.insert_bbox then
            return
        end

        table.insert(fit_blocks, block.insert_bbox)
    end

    return sorted_blocks
end

return Pack
