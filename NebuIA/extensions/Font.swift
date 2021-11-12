//
//  Font.swift
//  NebuIA
//
//  Created by Miguel on 25/06/21.
//

func dynamicFontSizeForIphone(fontSize : CGFloat) -> CGFloat
{
    var current_Size : CGFloat = 0.0
    current_Size = (UIScreen.main.bounds.width/320) //320*568 is my base
    let FinalSize : CGFloat = fontSize * current_Size
    return FinalSize

}
