export default () => {
    const date = Variable("", {
        poll: [30000, 'date "+  %I:%M    %m/%d"'],
    })

    return Widget.Label({
        class_name: "bar-widget clock",
        label: date.bind(),
    })
}
