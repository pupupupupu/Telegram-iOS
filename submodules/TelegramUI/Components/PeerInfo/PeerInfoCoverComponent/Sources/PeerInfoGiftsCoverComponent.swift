    let maxPossibleDistance = hypot(self.containerSize.width, self.containerSize.height) / 2
    while positions.count < count && attempts < maxAttempts {
        attempts += 1
        let placeOnLeftSide = rightPositions >= leftPositions
        let orbitRangeSize = self.outerOrbitRange.max - self.outerOrbitRange.min
        let orbitDistanceFactor = self.outerOrbitRange.min + orbitRangeSize * CGFloat(self.lokiRng.next())
        let distance = orbitDistanceFactor * centerRadius
        let angleRange: CGFloat = placeOnLeftSide ? .pi : .pi
        let angleOffset: CGFloat = placeOnLeftSide ? .pi / 2 : -(.pi / 2)
        let angle = angleOffset + angleRange * CGFloat(self.lokiRng.next())

        let absolutePosition = getAbsolutePosition(
            distance: distance,
            angle: angle,
            centerPoint: centerPoint
        )
        if absolutePosition.x - itemSize.width / 2 < self.edgePadding
            || absolutePosition.x + itemSize.width / 2 > self.containerSize.width - self.edgePadding
            || absolutePosition.y - itemSize.height / 2 < self.edgePadding
            || absolutePosition.y + itemSize.height / 2 > self.containerSize.height - self.edgePadding {
            continue
        }

        let itemRect = CGRect(
            x: absolutePosition.x - itemSize.width / 2,
            y: absolutePosition.y - itemSize.height / 2,
            width: itemSize.width,
            height: itemSize.height
        )
        if self.isValidPosition(
            itemRect,
            existingPositions: positions.map {
                getAbsolutePosition(
                    distance: $0.distance,
                    angle: $0.angle,
                    centerPoint:
