(**

  This module contains the old style RTTI information.

  @Author  David Hoyle
  @Version 1.0
  @Date    18 Dec 2016

**)
Unit DGHOLDRTTIFunctions;

Interface

Uses
  TypInfo,
  ComCtrls;

  Procedure ProcessOldProperties(View : TListView; ptrData : Pointer);

Implementation

Uses
  SysUtils,
  Classes,
  Graphics,
  Controls;

(**

  This function returns the enumerate valeu name for the given pointer item.

  @precon  ptrData and PropListItem must be valid.
  @postcon Returns the name of the enumerate value.

  @param   ptrData      as a Pointer
  @param   PropListItem as a PPropInfo
  @return  a String

**)
Function PropertyValueEnumerate(ptrData  :Pointer; PropListItem : PPropInfo): String;

Begin
  Result := GetEnumName(PropListItem.PropType^, GetOrdProp(TObject(ptrData), PropListItem));
End;

(**

  This function returns the value of the integer.

  @precon  ptrData and PropListItem must be valid instances.
  @postcon Returns the value of the integer.

  @param   ptrData      as a Pointer
  @param   PropListItem as a PPropInfo
  @return  a String

**)
Function PropertyValueInteger(ptrData : Pointer; PropListItem : PPropInfo): String;

Begin
  Result := IntToStr(GetOrdProp(TObject(ptrData), PropListItem))
End;

(**

  This function returns the memoet addresses of the method.

  @precon  ptrData and PropListItem must be valid.
  @postcon Returns the memoet addresses of the method.

  @param   ptrData      as a Pointer
  @param   PropListItem as a PPropInfo
  @return  a String

**)
Function PropertyValueMethod(ptrData: Pointer; PropListItem: PPropInfo): String;

Var
  Method: TMethod;

Begin
  Method := GetMethodProp(TObject(ptrData), PropListItem);
  Result := '$' + IntToHex(Integer(Method.Data), 8) +
    '::$' + IntToHex(Integer(Method.Code), 8);
  If Result = '$00000000::$00000000' Then
    Result := '(Unassigned)';
End;

(**

  This function returns a text represetnation of the values that are contained in the
  set.

  @precon  ptrData and PropListItem must be valid instances.
  @postcon Returns a text represetnation of the values that are contained in the set.

  @param   ptrData      as a Pointer
  @param   PropListItem as a PPropInfo
  @return  a String

**)
Function PropertyValueSet(ptrData: Pointer; PropListItem: PPropInfo): String;

Var
  S: TIntegerSet;
  TypeInfo: PTypeInfo;
  j: Integer;

Begin
  TypeInfo := GetTypeData(PropListItem.PropType^)^.CompType^;
  Integer(S) := GetOrdProp(TObject(ptrData), PropListItem);
  Result := '[';
  For j := 0 To SizeOf(Integer) * 8 - 1 Do
    If j In S Then
      Begin
        If Length(Result) <> 1 Then
          Result := Result + ', ';
        Result := Result + GetEnumName(TypeInfo, j);
      End;
  Result := Result + ']';
End;

(**

  This procedure exrtacts the old published properties of the given object pointer and
  adds a list view item for each property.

  @precon  View and ptrData must be valid instances.
  @postcon A list view item is added to the view for eac npublished property of the
           object.

  @param   View    as a TListView
  @param   ptrData as a Pointer

**)
Procedure ProcessOldProperties(View : TListView; ptrData : Pointer);

Var
  lvItem : TListItem;
  i: Integer;
  PropList: PPropList;
  iNumOfProps: Integer;

Begin
  View.Items.BeginUpdate;
  Try
    View.Items.Clear;
    GetMem(PropList, SizeOf(TPropList));
    Try
      iNumOfProps := GetPropList(TComponent(ptrData).ClassInfo, tkAny, PropList);
      For i := 0 To iNumOfProps - 1 Do
        Begin
          lvItem := View.Items.Add;
          lvItem.Caption := String(PropList[i].Name);
          lvItem.SubItems.Add(String(PropList[i].PropType^.Name));
          lvItem.ImageIndex := Integer(PropList[i].PropType^.Kind);
          lvItem.SubItems.Add(GetEnumName(TypeInfo(TTypeKind),
            Ord(PropList[i].PropType^.Kind)));
          //Try
            Case PropList[i].PropType^.Kind Of
              tkUnknown:     lvItem.SubItems.Add('< Unknown >');
              tkInteger:     lvItem.SubItems.Add(PropertyValueInteger(ptrData, PropList[i]));
              tkChar:        lvItem.SubItems.Add('[== Unhandled ==]');
              tkEnumeration: lvItem.SubItems.Add(PropertyValueEnumerate(ptrData, PropList[i]));
              tkFloat:       lvItem.SubItems.Add(FloatToStr(GetFloatProp(TObject(ptrData), PropList[i])));
              tkString:      lvItem.SubItems.Add(GetStrProp(TObject(ptrData), PropList[i]));
              tkSet:         lvItem.SubItems.Add(PropertyValueSet(ptrData, PropList[i]));
              tkClass:       lvItem.SubItems.Add('< Class >');
              tkMethod:      lvItem.SubItems.Add(PropertyValueMethod(ptrData, PropList[i]));
              tkWChar:       lvItem.SubItems.Add('[== Unhandled ==]');
              tkLString:     lvItem.SubItems.Add(GetStrProp(TObject(ptrData), PropList[i]));
              tkWString:     lvItem.SubItems.Add(GetWideStrProp(TObject(ptrData), PropList[i]));
              tkVariant:     lvItem.SubItems.Add('< Variant >');
              tkArray:       lvItem.SubItems.Add('< Array >');
              tkRecord:      lvItem.SubItems.Add('< Record >');
              tkInterface:   lvItem.SubItems.Add('< Inteface >' {GetInterfaceProp(TObject(ptrData), PropList[i])});
              tkInt64:       lvItem.SubItems.Add(IntToStr(GetInt64Prop(TObject(ptrData), PropList[i])));
              tkDynArray:    lvItem.SubItems.Add(Format('%x', [GetDynArrayProp(TObject(ptrData), PropList[i])]));
              tkUString:     lvItem.SubItems.Add(GetUnicodeStrProp(TObject(ptrData), PropList[i]));
              tkClassRef:    lvItem.SubItems.Add('< ClassRef >');
              tkPointer:     lvItem.SubItems.Add('< Pointer >');
              tkProcedure:   lvItem.SubItems.Add('< Procedure >');
            Else
              lvItem.SubItems.Add('< MISSING PROPERTY HANDLER >');
            End;
          //Except
          //  On E : Exception Do
          //    lvItem.SubItems.Add(Format('Exception: %s', [E.Message]));
          //End;
          If lvItem.SubItems[0] = 'TColor' Then
            lvItem.SubItems[2] := ColorToString(StrToInt(lvItem.SubItems[2]));
          If lvItem.SubItems[0] = 'TCursor' Then
            lvItem.SubItems[2] := CursorToString(StrToInt(lvItem.SubItems[2]));
        End;
    Finally
      FreeMem(PropList, SizeOf(TPropList));
    End;
  Finally
    View.Items.EndUpdate;
  End;
End;

End.
