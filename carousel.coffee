(($) ->
    $.fn.flexibleCarousel = (jsInit) ->

        log = (text) ->
            try
                console.log text
            catch error
                ;

        configure = (() ->
            vars =
                hasNext: true
                nextItem: 1
                busyLoadingItem: false
                rotateBusy: false
                wantsToRotateNext: false

            defaultConfig =
                # in case that @ == $('.flefible-carousel')
                $screen: $(@).find '.screen'
                $arrowPrev: $(@).find '.arrow-prev'
                $arrowNext: $(@).find '.arrow-next'
                item: (() -> $(@).find('.item')).bind @
                active_class: 'active'
                active: (() -> $(@).find('.item.active')).bind @
                url: '/flefible-carousel/item/'
                duration: 400
                responseKeys:
                    hasNext: 'hasNext'
                    content: 'content'
                requestData:
                    itemNumKey: 'itemNum'
                    extra: {}
                dummy: true
                # loging
                name: 'flexibleCarousel'
                log: true

            $.extend defaultConfig, jsInit
            $(@).data 'flexibleCarousel.vars', vars
            $(@).data 'flexibleCarousel.config', defaultConfig
            defaultConfig
        ).bind @

        # Handlers

        getItem = ((async = true) ->
            vars = $(@).data 'flexibleCarousel.vars'
            config = $(@).data 'flexibleCarousel.config'

            if not vars.busyLoadingItem and vars.hasNext
                vars.busyLoadingItem = true
                data = {}
                data[config.requestData.itemNumKey] = vars.nextItem
                $.extend data, config.requestData.extra

                $.ajax
                    async: async
                    url: config.url
                    type: 'GET'
                    dataType: 'JSON'
                    data: data
                    success: ((response) ->

                        # append
                        $html = $ response[config.responseKeys.content]
                        if config.dummy and vars.nextItem == 1
                            config.$screen.html $html.addClass config.active_class
                        else
                            config.$screen.append $html

                        # screen width
                        width = config.item().outerWidth true
                        size = config.item().size()
                        config.$screen.css
                            width: width * size

                        # does it has next
                        if response.hasNext
                            vars.hasNext = true
                            vars.nextItem = vars.nextItem + 1
                        else
                            vars.hasNext = false

                        vars.busyLoadingItem = false
                        $(@).trigger 'flexibleCarousel.itemLoaded', vars.nextItem - 1
                    ).bind @
        ).bind @

        rotate = ((direction) ->
            vars = $(@).data 'flexibleCarousel.vars'
            config = $(@).data 'flexibleCarousel.config'
            rotated = false

            if not vars.rotateBusy
                vars.rotateBusy = true
                vars.wantsToRotateNext = false
                $active = config.active()
                $prev = $active.prev()
                $next = $active.next()
                left = config.$screen.css 'left'
                left = parseInt if left == 'auto' then 0 else left

                # prev
                if direction == 'prev' and $prev.size()
                    $active.removeClass config.active_class
                    $prev.addClass config.active_class
                    config.$screen.animate
                        left: left + $prev.width()
                    , config.duration
                    rotated = true
                    if !config.active().prev().size()
                        config.$arrowPrev.addClass('disable')

                # next
                else if direction == 'next' and $next.size()
                    $active.removeClass config.active_class
                    $next.addClass config.active_class
                    config.$screen.animate
                        left: left - $next.width()
                    , config.duration
                    rotated = true
                else if direction == 'next' and vars.hasNext
                    vars.wantsToRotateNext = true
                    if config.log
                        log "#{config.name}: want to rotate"

                if config.log
                    if rotated
                        log "#{config.name}: rotate #{direction}"
                    else
                        log "#{config.name}: rotation - deny"

                # prevent async animate
                setTimeout () ->
                    vars.rotateBusy = false
                , config.duration
        ).bind(@)

        clickPrev = () ->
            rotate 'prev'
            config.$arrowNext.removeClass('disable')

        clickNext = () ->
            vars = $(@).data 'flexibleCarousel.vars'
            config = $(@).data 'flexibleCarousel.config'

            $(@).trigger('flexibleCarousel.needItem')
            if !vars.hasNext
                config.$arrowNext.addClass('disable')
            rotate 'next'

            config.$arrowPrev.removeClass('disable')

        itemLoaded = (e, item) ->
            vars = $(@).data 'flexibleCarousel.vars'
            config = $(@).data 'flexibleCarousel.config'
            if config.log
                log "#{config.name}: #{item} item loaded"
            if vars.wantsToRotateNext
                rotate 'next'

        # entry point
        config = configure jsInit
        $(@).bind 'flexibleCarousel.itemLoaded', itemLoaded
        getItem false
        getItem false
        $(@).bind 'flexibleCarousel.needItem', getItem
        config.$arrowPrev.click clickPrev.bind @
        config.$arrowNext.click clickNext.bind @
        @
)(jQuery)
