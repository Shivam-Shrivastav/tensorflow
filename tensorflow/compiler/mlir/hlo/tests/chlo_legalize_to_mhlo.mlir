// RUN: mlir-hlo-opt --chlo-legalize-to-hlo --split-input-file %s | FileCheck %s

// CHECK-LABEL: @asinh_bf16
// CHECK-SAME: %[[ARG:.*]]: tensor<bf16>
func @asinh_bf16(%arg : tensor<bf16>) -> tensor<bf16> {
  // Check for the bf16-specific max value.
  // CHECK: mhlo.constant dense<3.389{{.*}}e+38>
  %result = "chlo.asinh"(%arg) : (tensor<bf16>) -> tensor<bf16>
  return %result : tensor<bf16>
}

// CHECK-LABEL: @asinh_f16
// CHECK-SAME: %[[ARG:.*]]: tensor<f16>
func @asinh_f16(%arg : tensor<f16>) -> tensor<f16> {
  // Check for the f16-specific max value.
  // CHECK: mhlo.constant dense<6.550{{.*}}e+04>
  %result = "chlo.asinh"(%arg) : (tensor<f16>) -> tensor<f16>
  return %result : tensor<f16>
}

// CHECK-LABEL: @asinh_f32
// CHECK-SAME: %[[ARG:.*]]: tensor<f32>
func @asinh_f32(%arg : tensor<f32>) -> tensor<f32> {
  // Check for the f32-specific max value.
  // CHECK: mhlo.constant dense<3.402{{.*}}E+38>
  %result = "chlo.asinh"(%arg) : (tensor<f32>) -> tensor<f32>
  return %result : tensor<f32>
}

// CHECK-LABEL: @asinh_f64
// CHECK-SAME: %[[ARG:.*]]: tensor<f64>
func @asinh_f64(%arg : tensor<f64>) -> tensor<f64> {
  // CHECK: %[[TMP_0:.*]] = "mhlo.sign"(%[[ARG]])
  // CHECK: %[[TMP_1:.*]] = "mhlo.abs"(%[[ARG]])
  // CHECK: %[[TMP_2:.*]] = mhlo.constant dense<1.797{{.*}}E+308>
  // CHECK: %[[TMP_3:.*]] = "mhlo.sqrt"(%[[TMP_2]])
  // CHECK: %[[TMP_4:.*]] = "mhlo.compare"(%[[TMP_1]], %[[TMP_3]]) {comparison_direction = "GE"}
  // CHECK: %[[TMP_5:.*]] = "mhlo.abs"(%[[ARG]])
  // CHECK: %[[TMP_6:.*]] = "mhlo.log"(%[[TMP_5]])
  // CHECK: %[[TMP_7:.*]] = mhlo.constant dense<2.000{{.*}}e+00>
  // CHECK: %[[TMP_8:.*]] = "mhlo.log"(%[[TMP_7]])
  // CHECK: %[[TMP_9:.*]] = mhlo.add %[[TMP_6]], %[[TMP_8]]
  // CHECK: %[[TMP_10:.*]] = "mhlo.abs"(%[[ARG]])
  // CHECK: %[[TMP_11:.*]] = mhlo.constant dense<1.000{{.*}}e+00>
  // CHECK: %[[TMP_12:.*]] = "mhlo.compare"(%[[TMP_10]], %[[TMP_11]]) {comparison_direction = "LE"}
  // CHECK: %[[TMP_13:.*]] = "mhlo.abs"(%[[ARG]])
  // CHECK: %[[TMP_14:.*]] = "mhlo.abs"(%[[ARG]])
  // CHECK: %[[TMP_15:.*]] = "mhlo.abs"(%[[ARG]])
  // CHECK: %[[TMP_16:.*]] = "mhlo.abs"(%[[ARG]])
  // CHECK: %[[TMP_17:.*]] = "mhlo.abs"(%[[ARG]])
  // CHECK: %[[TMP_18:.*]] = mhlo.multiply %[[TMP_16]], %[[TMP_17]]
  // CHECK: %[[TMP_19:.*]] = mhlo.constant dense<1.000{{.*}}e+00>
  // CHECK: %[[TMP_20:.*]] = mhlo.add %[[TMP_18]], %[[TMP_19]]
  // CHECK: %[[TMP_21:.*]] = "mhlo.sqrt"(%[[TMP_20]])
  // CHECK: %[[TMP_22:.*]] = mhlo.constant dense<1.000{{.*}}e+00>
  // CHECK: %[[TMP_23:.*]] = mhlo.add %[[TMP_22]], %[[TMP_21]]
  // CHECK: %[[TMP_24:.*]] = mhlo.divide %[[TMP_15]], %[[TMP_23]]
  // CHECK: %[[TMP_25:.*]] = mhlo.multiply %[[TMP_14]], %[[TMP_24]]
  // CHECK: %[[TMP_26:.*]] = mhlo.add %[[TMP_13]], %[[TMP_25]]
  // CHECK: %[[TMP_27:.*]] = "mhlo.log_plus_one"(%[[TMP_26]])
  // CHECK: %[[TMP_28:.*]] = "mhlo.abs"(%[[ARG]])
  // CHECK: %[[TMP_29:.*]] = "mhlo.abs"(%[[ARG]])
  // CHECK: %[[TMP_30:.*]] = "mhlo.abs"(%[[ARG]])
  // CHECK: %[[TMP_31:.*]] = mhlo.multiply %[[TMP_29]], %[[TMP_30]]
  // CHECK: %[[TMP_32:.*]] = mhlo.constant dense<1.000{{.*}}e+00>
  // CHECK: %[[TMP_33:.*]] = mhlo.add %[[TMP_31]], %[[TMP_32]]
  // CHECK: %[[TMP_34:.*]] = "mhlo.sqrt"(%[[TMP_33]])
  // CHECK: %[[TMP_35:.*]] = mhlo.add %[[TMP_28]], %[[TMP_34]]
  // CHECK: %[[TMP_36:.*]] = "mhlo.log"(%[[TMP_35]])
  // CHECK: %[[TMP_37:.*]] = "mhlo.select"(%[[TMP_12]], %[[TMP_27]], %[[TMP_36]])
  // CHECK: %[[TMP_38:.*]] = "mhlo.select"(%[[TMP_4]], %[[TMP_9]], %[[TMP_37]])
  // CHECK: %[[RES:.*]] = mhlo.multiply %[[TMP_0]], %[[TMP_38]]
  // CHECK: return %[[RES]]
  %result = "chlo.asinh"(%arg) : (tensor<f64>) -> tensor<f64>
  return %result : tensor<f64>
}

// Lower statically shaped `constant_like` to constant.
// CHECK-LABEL: @constant_like_static_shape
func @constant_like_static_shape(%arg : tensor<1x2xi64>) -> tensor<1x2xf32> {
  // CHECK: %[[RESULT:.*]] = mhlo.constant dense<3.200000e+00> : tensor<1x2xf32>
  // CHECK: return %[[RESULT]]
  %result = "chlo.constant_like"(%arg) { value = 3.2 : f32 }
      : (tensor<1x2xi64>) -> tensor<1x2xf32>
  return %result : tensor<1x2xf32>
}

// Lower dynamically shaped `constant_like` to broadcasted constant.
// CHECK-LABEL: constant_like_dynamic_shape
// CHECK-SAME: (%[[ARG:.*]]: tensor<?x?xi64>)
func @constant_like_dynamic_shape(%arg : tensor<?x?xi64>) -> tensor<?x?xf32> {
  // CHECK: %[[CONSTANT:.*]] = mhlo.constant dense<3.200000e+00> : tensor<f32>
  // CHECK: %[[UNCASTED_SHAPE:.*]] = shape.shape_of %[[ARG]] : tensor<?x?xi64> -> tensor<?xindex>
  // CHECK: %[[SHAPE:.*]] = tensor.cast %[[UNCASTED_SHAPE]] : tensor<?xindex> to tensor<2xindex>
  // CHECK: %[[BROADCASTED_CONSTANT:.*]] = "mhlo.dynamic_broadcast_in_dim"(%[[CONSTANT]], %[[SHAPE]]) {broadcast_dimensions = dense<> : tensor<0xi64>} : (tensor<f32>, tensor<2xindex>) -> tensor<?x?xf32>
  // CHECK: return %[[BROADCASTED_CONSTANT]] : tensor<?x?xf32>
  %result = "chlo.constant_like"(%arg) { value = 3.2 : f32 }
      : (tensor<?x?xi64>) -> tensor<?x?xf32>
  return %result : tensor<?x?xf32>
}

// CHECK-LABEL: func @conj
func @conj(%arg0: tensor<3xcomplex<f32>>) -> tensor<3xcomplex<f32>> {
  // CHECK-SAME: ([[INPUT:%.*]]: tensor
  // CHECK-NEXT: [[R1:%.*]] = "mhlo.real"([[INPUT]])
  // CHECK-NEXT: [[R2:%.*]] = "mhlo.imag"([[INPUT]])
  // CHECK-NEXT: [[R3:%.*]] = "mhlo.negate"([[R2]])
  // CHECK-NEXT: [[R4:%.*]] = "mhlo.complex"([[R1]], [[R3]])
  %1 = "chlo.conj"(%arg0) : (tensor<3xcomplex<f32>>) -> tensor<3xcomplex<f32>>
  return %1 : tensor<3xcomplex<f32>>
}

// CHECK-LABEL: @erf_f64
// CHECK-SAME: %[[ARG:.*]]: tensor<f64>
func @erf_f64(%arg : tensor<f64>) -> tensor<f64> {
  // CHECK: %[[TMP_0:.*]] = mhlo.multiply %[[ARG]], %[[ARG]]
  // CHECK: %[[TMP_1:.*]] = mhlo.constant dense<0.000000e+00>
  // CHECK: %[[TMP_2:.*]] = mhlo.multiply %[[TMP_1]], %[[TMP_0]]
  // CHECK: %[[TMP_3:.*]] = mhlo.constant dense<9.6049737398705161>
  // CHECK: %[[TMP_4:.*]] = mhlo.add %[[TMP_2]], %[[TMP_3]]
  // CHECK: %[[TMP_5:.*]] = mhlo.multiply %[[TMP_4]], %[[TMP_0]]
  // CHECK: %[[TMP_6:.*]] = mhlo.constant dense<90.026019720384269>
  // CHECK: %[[TMP_7:.*]] = mhlo.add %[[TMP_5]], %[[TMP_6]]
  // CHECK: %[[TMP_8:.*]] = mhlo.multiply %[[TMP_7]], %[[TMP_0]]
  // CHECK: %[[TMP_9:.*]] = mhlo.constant dense<2232.0053459468431>
  // CHECK: %[[TMP_10:.*]] = mhlo.add %[[TMP_8]], %[[TMP_9]]
  // CHECK: %[[TMP_11:.*]] = mhlo.multiply %[[TMP_10]], %[[TMP_0]]
  // CHECK: %[[TMP_12:.*]] = mhlo.constant dense<7003.3251411280507>
  // CHECK: %[[TMP_13:.*]] = mhlo.add %[[TMP_11]], %[[TMP_12]]
  // CHECK: %[[TMP_14:.*]] = mhlo.multiply %[[TMP_13]], %[[TMP_0]]
  // CHECK: %[[TMP_15:.*]] = mhlo.constant dense<55592.301301039493>
  // CHECK: %[[TMP_16:.*]] = mhlo.add %[[TMP_14]], %[[TMP_15]]
  // CHECK: %[[TMP_17:.*]] = mhlo.multiply %[[ARG]], %[[TMP_16]]
  // CHECK: %[[TMP_18:.*]] = mhlo.constant dense<0.000000e+00>
  // CHECK: %[[TMP_19:.*]] = mhlo.multiply %[[TMP_18]], %[[TMP_0]]
  // CHECK: %[[TMP_20:.*]] = mhlo.constant dense<1.000000e+00>
  // CHECK: %[[TMP_21:.*]] = mhlo.add %[[TMP_19]], %[[TMP_20]]
  // CHECK: %[[TMP_22:.*]] = mhlo.multiply %[[TMP_21]], %[[TMP_0]]
  // CHECK: %[[TMP_23:.*]] = mhlo.constant dense<33.561714164750313>
  // CHECK: %[[TMP_24:.*]] = mhlo.add %[[TMP_22]], %[[TMP_23]]
  // CHECK: %[[TMP_25:.*]] = mhlo.multiply %[[TMP_24]], %[[TMP_0]]
  // CHECK: %[[TMP_26:.*]] = mhlo.constant dense<521.35794978015269>
  // CHECK: %[[TMP_27:.*]] = mhlo.add %[[TMP_25]], %[[TMP_26]]
  // CHECK: %[[TMP_28:.*]] = mhlo.multiply %[[TMP_27]], %[[TMP_0]]
  // CHECK: %[[TMP_29:.*]] = mhlo.constant dense<4594.3238297098014>
  // CHECK: %[[TMP_30:.*]] = mhlo.add %[[TMP_28]], %[[TMP_29]]
  // CHECK: %[[TMP_31:.*]] = mhlo.multiply %[[TMP_30]], %[[TMP_0]]
  // CHECK: %[[TMP_32:.*]] = mhlo.constant dense<22629.000061389095>
  // CHECK: %[[TMP_33:.*]] = mhlo.add %[[TMP_31]], %[[TMP_32]]
  // CHECK: %[[TMP_34:.*]] = mhlo.multiply %[[TMP_33]], %[[TMP_0]]
  // CHECK: %[[TMP_35:.*]] = mhlo.constant dense<49267.394260863592>
  // CHECK: %[[TMP_36:.*]] = mhlo.add %[[TMP_34]], %[[TMP_35]]
  // CHECK: %[[TMP_37:.*]] = mhlo.divide %[[TMP_17]], %[[TMP_36]]
  // CHECK: %[[TMP_38:.*]] = mhlo.constant dense<1.000000e+00>
  // CHECK: %[[TMP_39:.*]] = mhlo.multiply %[[ARG]], %[[ARG]]
  // CHECK: %[[TMP_40:.*]] = "mhlo.negate"(%[[TMP_39]])
  // CHECK: %[[TMP_41:.*]] = "mhlo.exponential"(%[[TMP_40]])
  // CHECK: %[[TMP_42:.*]] = "mhlo.abs"(%[[ARG]])
  // CHECK: %[[TMP_43:.*]] = mhlo.constant dense<0.000000e+00>
  // CHECK: %[[TMP_44:.*]] = mhlo.multiply %[[TMP_43]], %[[TMP_42]]
  // CHECK: %[[TMP_45:.*]] = mhlo.constant dense<2.4619698147353052E-10>
  // CHECK: %[[TMP_46:.*]] = mhlo.add %[[TMP_44]], %[[TMP_45]]
  // CHECK: %[[TMP_47:.*]] = mhlo.multiply %[[TMP_46]], %[[TMP_42]]
  // CHECK: %[[TMP_48:.*]] = mhlo.constant dense<0.56418956483106886>
  // CHECK: %[[TMP_49:.*]] = mhlo.add %[[TMP_47]], %[[TMP_48]]
  // CHECK: %[[TMP_50:.*]] = mhlo.multiply %[[TMP_49]], %[[TMP_42]]
  // CHECK: %[[TMP_51:.*]] = mhlo.constant dense<7.4632105644226989>
  // CHECK: %[[TMP_52:.*]] = mhlo.add %[[TMP_50]], %[[TMP_51]]
  // CHECK: %[[TMP_53:.*]] = mhlo.multiply %[[TMP_52]], %[[TMP_42]]
  // CHECK: %[[TMP_54:.*]] = mhlo.constant dense<48.637197098568137>
  // CHECK: %[[TMP_55:.*]] = mhlo.add %[[TMP_53]], %[[TMP_54]]
  // CHECK: %[[TMP_56:.*]] = mhlo.multiply %[[TMP_55]], %[[TMP_42]]
  // CHECK: %[[TMP_57:.*]] = mhlo.constant dense<196.5208329560771>
  // CHECK: %[[TMP_58:.*]] = mhlo.add %[[TMP_56]], %[[TMP_57]]
  // CHECK: %[[TMP_59:.*]] = mhlo.multiply %[[TMP_58]], %[[TMP_42]]
  // CHECK: %[[TMP_60:.*]] = mhlo.constant dense<526.44519499547732>
  // CHECK: %[[TMP_61:.*]] = mhlo.add %[[TMP_59]], %[[TMP_60]]
  // CHECK: %[[TMP_62:.*]] = mhlo.multiply %[[TMP_61]], %[[TMP_42]]
  // CHECK: %[[TMP_63:.*]] = mhlo.constant dense<934.52852717195765>
  // CHECK: %[[TMP_64:.*]] = mhlo.add %[[TMP_62]], %[[TMP_63]]
  // CHECK: %[[TMP_65:.*]] = mhlo.multiply %[[TMP_64]], %[[TMP_42]]
  // CHECK: %[[TMP_66:.*]] = mhlo.constant dense<1027.5518868951572>
  // CHECK: %[[TMP_67:.*]] = mhlo.add %[[TMP_65]], %[[TMP_66]]
  // CHECK: %[[TMP_68:.*]] = mhlo.multiply %[[TMP_67]], %[[TMP_42]]
  // CHECK: %[[TMP_69:.*]] = mhlo.constant dense<557.53533536939938>
  // CHECK: %[[TMP_70:.*]] = mhlo.add %[[TMP_68]], %[[TMP_69]]
  // CHECK: %[[TMP_71:.*]] = mhlo.multiply %[[TMP_41]], %[[TMP_70]]
  // CHECK: %[[TMP_72:.*]] = mhlo.constant dense<0.000000e+00>
  // CHECK: %[[TMP_73:.*]] = mhlo.multiply %[[TMP_72]], %[[TMP_42]]
  // CHECK: %[[TMP_74:.*]] = mhlo.constant dense<1.000000e+00>
  // CHECK: %[[TMP_75:.*]] = mhlo.add %[[TMP_73]], %[[TMP_74]]
  // CHECK: %[[TMP_76:.*]] = mhlo.multiply %[[TMP_75]], %[[TMP_42]]
  // CHECK: %[[TMP_77:.*]] = mhlo.constant dense<13.228195115474499>
  // CHECK: %[[TMP_78:.*]] = mhlo.add %[[TMP_76]], %[[TMP_77]]
  // CHECK: %[[TMP_79:.*]] = mhlo.multiply %[[TMP_78]], %[[TMP_42]]
  // CHECK: %[[TMP_80:.*]] = mhlo.constant dense<86.707214088598973>
  // CHECK: %[[TMP_81:.*]] = mhlo.add %[[TMP_79]], %[[TMP_80]]
  // CHECK: %[[TMP_82:.*]] = mhlo.multiply %[[TMP_81]], %[[TMP_42]]
  // CHECK: %[[TMP_83:.*]] = mhlo.constant dense<354.93777888781989>
  // CHECK: %[[TMP_84:.*]] = mhlo.add %[[TMP_82]], %[[TMP_83]]
  // CHECK: %[[TMP_85:.*]] = mhlo.multiply %[[TMP_84]], %[[TMP_42]]
  // CHECK: %[[TMP_86:.*]] = mhlo.constant dense<975.70850174320549>
  // CHECK: %[[TMP_87:.*]] = mhlo.add %[[TMP_85]], %[[TMP_86]]
  // CHECK: %[[TMP_88:.*]] = mhlo.multiply %[[TMP_87]], %[[TMP_42]]
  // CHECK: %[[TMP_89:.*]] = mhlo.constant dense<1823.9091668790973>
  // CHECK: %[[TMP_90:.*]] = mhlo.add %[[TMP_88]], %[[TMP_89]]
  // CHECK: %[[TMP_91:.*]] = mhlo.multiply %[[TMP_90]], %[[TMP_42]]
  // CHECK: %[[TMP_92:.*]] = mhlo.constant dense<2246.3376081871097>
  // CHECK: %[[TMP_93:.*]] = mhlo.add %[[TMP_91]], %[[TMP_92]]
  // CHECK: %[[TMP_94:.*]] = mhlo.multiply %[[TMP_93]], %[[TMP_42]]
  // CHECK: %[[TMP_95:.*]] = mhlo.constant dense<1656.6630919416134>
  // CHECK: %[[TMP_96:.*]] = mhlo.add %[[TMP_94]], %[[TMP_95]]
  // CHECK: %[[TMP_97:.*]] = mhlo.multiply %[[TMP_96]], %[[TMP_42]]
  // CHECK: %[[TMP_98:.*]] = mhlo.constant dense<557.53534081772773>
  // CHECK: %[[TMP_99:.*]] = mhlo.add %[[TMP_97]], %[[TMP_98]]
  // CHECK: %[[TMP_100:.*]] = mhlo.divide %[[TMP_71]], %[[TMP_99]]
  // CHECK: %[[TMP_101:.*]] = mhlo.constant dense<0.000000e+00>
  // CHECK: %[[TMP_102:.*]] = mhlo.multiply %[[TMP_101]], %[[TMP_42]]
  // CHECK: %[[TMP_103:.*]] = mhlo.constant dense<0.56418958354775506>
  // CHECK: %[[TMP_104:.*]] = mhlo.add %[[TMP_102]], %[[TMP_103]]
  // CHECK: %[[TMP_105:.*]] = mhlo.multiply %[[TMP_104]], %[[TMP_42]]
  // CHECK: %[[TMP_106:.*]] = mhlo.constant dense<1.275366707599781>
  // CHECK: %[[TMP_107:.*]] = mhlo.add %[[TMP_105]], %[[TMP_106]]
  // CHECK: %[[TMP_108:.*]] = mhlo.multiply %[[TMP_107]], %[[TMP_42]]
  // CHECK: %[[TMP_109:.*]] = mhlo.constant dense<5.0190504225118051>
  // CHECK: %[[TMP_110:.*]] = mhlo.add %[[TMP_108]], %[[TMP_109]]
  // CHECK: %[[TMP_111:.*]] = mhlo.multiply %[[TMP_110]], %[[TMP_42]]
  // CHECK: %[[TMP_112:.*]] = mhlo.constant dense<6.160210979930536>
  // CHECK: %[[TMP_113:.*]] = mhlo.add %[[TMP_111]], %[[TMP_112]]
  // CHECK: %[[TMP_114:.*]] = mhlo.multiply %[[TMP_113]], %[[TMP_42]]
  // CHECK: %[[TMP_115:.*]] = mhlo.constant dense<7.4097426995044895>
  // CHECK: %[[TMP_116:.*]] = mhlo.add %[[TMP_114]], %[[TMP_115]]
  // CHECK: %[[TMP_117:.*]] = mhlo.multiply %[[TMP_116]], %[[TMP_42]]
  // CHECK: %[[TMP_118:.*]] = mhlo.constant dense<2.9788666537210022>
  // CHECK: %[[TMP_119:.*]] = mhlo.add %[[TMP_117]], %[[TMP_118]]
  // CHECK: %[[TMP_120:.*]] = mhlo.multiply %[[TMP_41]], %[[TMP_119]]
  // CHECK: %[[TMP_121:.*]] = mhlo.constant dense<0.000000e+00>
  // CHECK: %[[TMP_122:.*]] = mhlo.multiply %[[TMP_121]], %[[TMP_42]]
  // CHECK: %[[TMP_123:.*]] = mhlo.constant dense<1.000000e+00>
  // CHECK: %[[TMP_124:.*]] = mhlo.add %[[TMP_122]], %[[TMP_123]]
  // CHECK: %[[TMP_125:.*]] = mhlo.multiply %[[TMP_124]], %[[TMP_42]]
  // CHECK: %[[TMP_126:.*]] = mhlo.constant dense<2.2605286322011726>
  // CHECK: %[[TMP_127:.*]] = mhlo.add %[[TMP_125]], %[[TMP_126]]
  // CHECK: %[[TMP_128:.*]] = mhlo.multiply %[[TMP_127]], %[[TMP_42]]
  // CHECK: %[[TMP_129:.*]] = mhlo.constant dense<9.3960352493800147>
  // CHECK: %[[TMP_130:.*]] = mhlo.add %[[TMP_128]], %[[TMP_129]]
  // CHECK: %[[TMP_131:.*]] = mhlo.multiply %[[TMP_130]], %[[TMP_42]]
  // CHECK: %[[TMP_132:.*]] = mhlo.constant dense<12.048953980809666>
  // CHECK: %[[TMP_133:.*]] = mhlo.add %[[TMP_131]], %[[TMP_132]]
  // CHECK: %[[TMP_134:.*]] = mhlo.multiply %[[TMP_133]], %[[TMP_42]]
  // CHECK: %[[TMP_135:.*]] = mhlo.constant dense<17.081445074756591>
  // CHECK: %[[TMP_136:.*]] = mhlo.add %[[TMP_134]], %[[TMP_135]]
  // CHECK: %[[TMP_137:.*]] = mhlo.multiply %[[TMP_136]], %[[TMP_42]]
  // CHECK: %[[TMP_138:.*]] = mhlo.constant dense<9.6089680906328585>
  // CHECK: %[[TMP_139:.*]] = mhlo.add %[[TMP_137]], %[[TMP_138]]
  // CHECK: %[[TMP_140:.*]] = mhlo.multiply %[[TMP_139]], %[[TMP_42]]
  // CHECK: %[[TMP_141:.*]] = mhlo.constant dense<3.3690764510008151>
  // CHECK: %[[TMP_142:.*]] = mhlo.add %[[TMP_140]], %[[TMP_141]]
  // CHECK: %[[TMP_143:.*]] = mhlo.divide %[[TMP_120]], %[[TMP_142]]
  // CHECK: %[[TMP_144:.*]] = mhlo.constant dense<8.000000e+00>
  // CHECK: %[[TMP_145:.*]] = "mhlo.compare"(%[[TMP_42]], %[[TMP_144]]) {comparison_direction = "LT"}
  // CHECK: %[[TMP_146:.*]] = "mhlo.select"(%[[TMP_145]], %[[TMP_100]], %[[TMP_143]])
  // CHECK: %[[TMP_147:.*]] = mhlo.constant dense<-709.78271289338397>
  // CHECK: %[[TMP_148:.*]] = "mhlo.compare"(%[[TMP_40]], %[[TMP_147]]) {comparison_direction = "LT"}
  // CHECK: %[[TMP_149:.*]] = mhlo.constant dense<0.000000e+00>
  // CHECK: %[[TMP_150:.*]] = "mhlo.select"(%[[TMP_148]], %[[TMP_149]], %[[TMP_146]])
  // CHECK: %[[TMP_152:.*]] = "mhlo.compare"(%[[ARG]], %[[TMP_149]]) {comparison_direction = "LT"}
  // CHECK: %[[TMP_153:.*]] = mhlo.constant dense<2.000000e+00>
  // CHECK: %[[TMP_154:.*]] = mhlo.subtract %[[TMP_153]], %[[TMP_150]]
  // CHECK: %[[TMP_155:.*]] = "mhlo.select"(%[[TMP_152]], %[[TMP_154]], %[[TMP_150]])
  // CHECK: %[[TMP_156:.*]] = mhlo.subtract %[[TMP_38]], %[[TMP_155]]
  // CHECK: %[[TMP_157:.*]] = "mhlo.abs"(%[[ARG]])
  // CHECK: %[[TMP_159:.*]] = "mhlo.compare"(%[[TMP_157]], %[[TMP_38]]) {comparison_direction = "LT"}
  // CHECK: %[[RESULT:.*]] = "mhlo.select"(%[[TMP_159]], %[[TMP_37]], %[[TMP_156]])
  // CHECK: return %[[RESULT]]
  %1 = "chlo.erf"(%arg) : (tensor<f64>) -> tensor<f64>
  return %1 : tensor<f64>
}

// CHECK-LABEL: @erf_f32
// CHECK-SAME: %[[ARG:.*]]: tensor<f32>
func @erf_f32(%arg : tensor<f32>) -> tensor<f32> {
  // CHECK: %[[TMP_0:.*]] = mhlo.constant dense<-4.000000e+00>
  // CHECK: %[[TMP_1:.*]] = mhlo.constant dense<4.000000e+00>
  // CHECK: %[[TMP_2:.*]] = "mhlo.clamp"(%[[TMP_0]], %[[ARG]], %[[TMP_1]])
  // CHECK: %[[TMP_3:.*]] = mhlo.multiply %[[TMP_2]], %[[TMP_2]]
  // CHECK: %[[TMP_4:.*]] = mhlo.constant dense<0.000000e+00>
  // CHECK: %[[TMP_5:.*]] = mhlo.multiply %[[TMP_4]], %[[TMP_3]]
  // CHECK: %[[TMP_6:.*]] = mhlo.constant dense<-2.72614237E-10>
  // CHECK: %[[TMP_7:.*]] = mhlo.add %[[TMP_5]], %[[TMP_6]]
  // CHECK: %[[TMP_8:.*]] = mhlo.multiply %[[TMP_7]], %[[TMP_3]]
  // CHECK: %[[TMP_9:.*]] = mhlo.constant dense<2.77068146E-8>
  // CHECK: %[[TMP_10:.*]] = mhlo.add %[[TMP_8]], %[[TMP_9]]
  // CHECK: %[[TMP_11:.*]] = mhlo.multiply %[[TMP_10]], %[[TMP_3]]
  // CHECK: %[[TMP_12:.*]] = mhlo.constant dense<-2.10102394E-6>
  // CHECK: %[[TMP_13:.*]] = mhlo.add %[[TMP_11]], %[[TMP_12]]
  // CHECK: %[[TMP_14:.*]] = mhlo.multiply %[[TMP_13]], %[[TMP_3]]
  // CHECK: %[[TMP_15:.*]] = mhlo.constant dense<-5.69250624E-5>
  // CHECK: %[[TMP_16:.*]] = mhlo.add %[[TMP_14]], %[[TMP_15]]
  // CHECK: %[[TMP_17:.*]] = mhlo.multiply %[[TMP_16]], %[[TMP_3]]
  // CHECK: %[[TMP_18:.*]] = mhlo.constant dense<-7.34990637E-4>
  // CHECK: %[[TMP_19:.*]] = mhlo.add %[[TMP_17]], %[[TMP_18]]
  // CHECK: %[[TMP_20:.*]] = mhlo.multiply %[[TMP_19]], %[[TMP_3]]
  // CHECK: %[[TMP_21:.*]] = mhlo.constant dense<-2.954600e-03>
  // CHECK: %[[TMP_22:.*]] = mhlo.add %[[TMP_20]], %[[TMP_21]]
  // CHECK: %[[TMP_23:.*]] = mhlo.multiply %[[TMP_22]], %[[TMP_3]]
  // CHECK: %[[TMP_24:.*]] = mhlo.constant dense<-0.0160960332>
  // CHECK: %[[TMP_25:.*]] = mhlo.add %[[TMP_23]], %[[TMP_24]]
  // CHECK: %[[TMP_26:.*]] = mhlo.constant dense<0.000000e+00>
  // CHECK: %[[TMP_27:.*]] = mhlo.multiply %[[TMP_26]], %[[TMP_3]]
  // CHECK: %[[TMP_28:.*]] = mhlo.constant dense<-1.45660715E-5>
  // CHECK: %[[TMP_29:.*]] = mhlo.add %[[TMP_27]], %[[TMP_28]]
  // CHECK: %[[TMP_30:.*]] = mhlo.multiply %[[TMP_29]], %[[TMP_3]]
  // CHECK: %[[TMP_31:.*]] = mhlo.constant dense<-2.13374049E-4>
  // CHECK: %[[TMP_32:.*]] = mhlo.add %[[TMP_30]], %[[TMP_31]]
  // CHECK: %[[TMP_33:.*]] = mhlo.multiply %[[TMP_32]], %[[TMP_3]]
  // CHECK: %[[TMP_34:.*]] = mhlo.constant dense<-0.00168282702>
  // CHECK: %[[TMP_35:.*]] = mhlo.add %[[TMP_33]], %[[TMP_34]]
  // CHECK: %[[TMP_36:.*]] = mhlo.multiply %[[TMP_35]], %[[TMP_3]]
  // CHECK: %[[TMP_37:.*]] = mhlo.constant dense<-0.00737332925>
  // CHECK: %[[TMP_38:.*]] = mhlo.add %[[TMP_36]], %[[TMP_37]]
  // CHECK: %[[TMP_39:.*]] = mhlo.multiply %[[TMP_38]], %[[TMP_3]]
  // CHECK: %[[TMP_40:.*]] = mhlo.constant dense<-0.0142647391>
  // CHECK: %[[TMP_41:.*]] = mhlo.add %[[TMP_39]], %[[TMP_40]]
  // CHECK: %[[TMP_42:.*]] = mhlo.multiply %[[TMP_2]], %[[TMP_25]]
  // CHECK: %[[RESULT:.*]] = mhlo.divide %[[TMP_42]], %[[TMP_41]]
  // CHECK: return %[[RESULT]]
  %1 = "chlo.erf"(%arg) : (tensor<f32>) -> tensor<f32>
  return %1 : tensor<f32>
}

// CHECK-LABEL: @erf_f16
// CHECK-SAME: %[[ARG:.*]]: tensor<f16>
func @erf_f16(%arg : tensor<f16>) -> tensor<f16> {
  // CHECK: "mhlo.convert"(%[[ARG]]) : (tensor<f16>) -> tensor<f32>
  // CHECK: %[[RESULT:.*]] = "mhlo.convert"(%{{.*}}) : (tensor<f32>) -> tensor<f16>
  // CHECK: return %[[RESULT]]
  %1 = "chlo.erf"(%arg) : (tensor<f16>) -> tensor<f16>
  return %1 : tensor<f16>
}

// CHECK-LABEL: @acosh
// CHECK-SAME: %[[ARG:.*]]: tensor<f16>
func @acosh(%arg: tensor<f16>) -> tensor<f16> {
  // CHECK: %[[MINUSONE:.*]] = mhlo.constant dense<-1.000000e+00>
  // CHECK: %[[CMP:.*]] = "mhlo.compare"(%[[ARG]], %[[MINUSONE]]) {comparison_direction = "LT"}
  // CHECK: %[[MAX:.*]] = mhlo.constant dense<6.550400e+04>
  // CHECK: %[[SQRTMAX:.*]] = "mhlo.sqrt"(%[[MAX]])
  // CHECK: %[[OVERFLOW:.*]] = "mhlo.compare"(%[[ARG]], %[[SQRTMAX]]) {comparison_direction = "GE"}
  // CHECK: %[[LOGARG:.*]] = "mhlo.log"(%[[ARG]])
  // CHECK: %[[TWO:.*]] = mhlo.constant dense<2.000000e+00>
  // CHECK: %[[LOGTWO:.*]] = "mhlo.log"(%[[TWO]])
  // CHECK: %[[OFLRES:.*]] = mhlo.add %[[LOGARG]], %[[LOGTWO]]
  // CHECK: %[[ONE:.*]] = mhlo.constant dense<1.000000e+00>
  // CHECK: %[[ARGPONE:.*]] = mhlo.add %[[ONE]], %[[ARG]]
  // CHECK: %[[MINUSONE2:.*]] = mhlo.constant dense<-1.000000e+00>
  // CHECK: %[[ARGMONE:.*]] = mhlo.add %[[MINUSONE2]], %[[ARG]]
  // CHECK: %[[MUL:.*]] = mhlo.multiply %[[ARGPONE]], %[[ARGMONE]]
  // CHECK: %[[SQRT:.*]] = "mhlo.sqrt"(%[[MUL]])
  // CHECK: %[[APSQRT:.*]] = mhlo.add %[[ARG]], %[[SQRT]]
  // CHECK: %[[LOGAPMUL:.*]] = "mhlo.log"(%[[APSQRT]])
  // CHECK: %[[SEL1:.*]] = "mhlo.select"(%[[OVERFLOW]], %[[OFLRES]], %[[LOGAPMUL]])
  // CHECK: %[[NAN:.*]] = mhlo.constant dense<0x7E00>
  // CHECK: %[[RESULT:.*]] = "mhlo.select"(%[[CMP]], %[[NAN]], %[[SEL1]])
  // CHECK: return %[[RESULT]]
  %1 = "chlo.acosh"(%arg) : (tensor<f16>) -> tensor<f16>
  return %1 : tensor<f16>
}
